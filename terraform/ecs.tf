# ecs.tf

# 資源：ECS 叢集 (用於 EC2 啟動類型)
resource "aws_ecs_cluster" "my_ec2_cluster" {
  name = "my-app-ec2-ecs-cluster-${var.aws_region}"
  tags = {
    Name = "my-app-ec2-ecs-cluster"
  }
}

# 數據源：獲取 ECS 優化 AMI (Amazon Linux 2)
# 如果此數據源持續報錯 "Your query returned no results."
# 可能是因為 AMI 名稱模式已變更或該區域沒有匹配的 AMI。
# 在這種情況下，你需要手動查找一個最新的 ECS 優化 AMI ID，並直接填寫 ami = "ami-xxxxxxxxxxxxxxxxx"。
# 你可以在 AWS EC2 控制台 -> AMI -> 搜索 "ECS Optimized" 或 "amzn2-ami-ecs" 來查找。
# 例如，在 ap-northeast-1 區域，一個可能的 AMI ID 範例可能是 "ami-0abcdef1234567890" (請替換為實際值)。
/*
data "aws_ami" "ecs_optimized_ami" {
  most_recent = true
  owners      = ["amazon"] # AWS 官方 AMI
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-gp2"] # 查找 ECS 優化 Amazon Linux 2 AMI
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
*/

# 資源：EC2 容器實例 (將運行 Docker 容器的 EC2 虛擬機)
resource "aws_instance" "ecs_container_instance" {
  # *** 重要：請將 ami 替換為你在 AWS 控制台查到的實際 AMI ID！ ***
  # 範例：ami = "ami-0abcdef1234567890"
  ami           = "ami-0016e0f5537d212b2" # <-- 請務必替換這個佔位符為你在 ap-northeast-1 區域查到的真實 AMI ID！
  instance_type = "t3.small"                        # 實例類型，根據需求調整
  subnet_id     = aws_subnet.public_subnet.id       # 指向公有子網
  vpc_security_group_ids = [aws_security_group.app_sg.id] # 應用安全組
  iam_instance_profile   = aws_iam_instance_profile.ecs_instance_profile.name # 附著 IAM 實例設定檔

  associate_public_ip_address = true # 讓 EC2 實例自動獲取公有 IP

  # User Data 腳本：在 EC2 啟動時安裝 Docker 並配置 ECS 代理
  user_data = <<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${aws_ecs_cluster.my_ec2_cluster.name} >> /etc/ecs/ecs.config
              sudo yum update -y
              sudo amazon-linux-extras install -y docker
              sudo systemctl enable docker --now
              sudo usermod -a -G docker ec2-user
              sudo systemctl enable ecs --now
              EOF

  tags = {
    Name = "ECS-Container-Instance-${var.aws_region}"
  }
}

# 資源：ECS 任務定義 (Task Definition，Docker 容器的藍圖)
resource "aws_ecs_task_definition" "app_task" {
  family                   = "my-app-task-definition-${var.aws_region}"
  # 對於 EC2 啟動類型，CPU 和 Memory 是容器的軟性限制，但仍需指定
  cpu                      = "256" # 已取消註解並設定 CPU
  memory                   = "512" # 已取消註解並設定 Memory
  network_mode             = "awsvpc" # 推薦使用 awsvpc 模式，提供更好的網路隔離
  requires_compatibilities = ["EC2"]  # 指定使用 EC2 啟動類型

  container_definitions = jsonencode([
    {
      name  = "my-app-container"
      image = "${data.aws_ecr_repository.app_ecr.repository_url}:${var.image_tag}" # 引用 ECR 映像檔和傳入的 image_tag
      cpu    = 256
      memory = 512
      portMappings = [
        {
          containerPort = 8080 # 你的應用程式監聽的 Port
          hostPort      = 8080 # 對於 awsvpc 模式，hostPort 通常與 containerPort 相同
        }
      ]
      environment = [
        # 可選：定義環境變數
        # { name = "APP_ENV", value = "production" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.app_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      # 健康檢查 (可選)
      # healthCheck = {
      #   command = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
      #   interval = 30
      #   timeout = 5
      #   retries = 3
      #   startPeriod = 60
      # }
    }
  ])

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn # 引用任務執行角色
  # task_role_arn      = aws_iam_role.ecs_task_role.arn          # 如果應用程式需要額外權限，請引用任務角色
  tags = {
    Name = "my-app-task-definition"
  }
}

# 資源：ECS 服務 (Service，確保任務持續運行)
resource "aws_ecs_service" "app_service" {
  name            = "my-app-ecs-service-${var.aws_region}"
  cluster         = aws_ecs_cluster.my_ec2_cluster.arn # 指向 ECS 叢集
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1 # 你希望運行的任務實例數量

  launch_type = "EC2" # 指定為 EC2 啟動類型

  # 由於 Task Definition 使用了 awsvpc 網路模式，這裡仍然需要網路配置
  network_configuration {
    subnets         = [aws_subnet.public_subnet.id] # 任務將運行在公有子網中
    security_groups = [aws_security_group.app_sg.id]  # 應用安全組
    # *** 修正點：移除 assign_public_ip = true ***
    # assign_public_ip = true # 此參數不支援 EC2 啟動類型與 awsvpc 網路模式組合
  }

  deployment_controller {
    type = "ECS" # 使用 ECS 原生部署方式 (滾動更新)
  }

  # 其他部署設定 (可選)
  # deployment_minimum_healthy_percent = 50
  # deployment_maximum_percent         = 200

  tags = {
    Name = "my-app-ecs-service"
  }
}
