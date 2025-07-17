# ecs.tf

# 資源：ECS 叢集 (用於 EC2 啟動類型)
resource "aws_ecs_cluster" "my_ec2_cluster" {
  name = "my-app-ec2-ecs-cluster-${var.aws_region}"
  tags = {
    Name = "my-app-ec2-ecs-cluster"
  }
}

# 數據源：獲取 ECS 優化 AMI (Amazon Linux 2)
# 請根據你的區域和需求選擇合適的 AMI
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

# 資源：EC2 容器實例 (將運行 Docker 容器的 EC2 虛擬機)
resource "aws_instance" "ecs_container_instance" {
  ami           = data.aws_ami.ecs_optimized_ami.id # 使用 ECS 優化 AMI
  instance_type = "t3.small"                        # 實例類型，根據需求調整
  # *** 修正點 1: 將 subnet_id 指向 public_subnet ***
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id] # 應用安全組
  iam_instance_profile   = aws_iam_instance_profile.ecs_instance_profile.name # 附著 IAM 實例設定檔

  # *** 修正點 2: 讓 EC2 實例自動獲取公有 IP ***
  associate_public_ip_address = true

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
  # 對於 EC2 啟動類型，CPU 和 Memory 是容器的軟性限制，不是強制分配
  # cpu                      = "256"
  # memory                   = "512"
  network_mode             = "awsvpc" # 推薦使用 awsvpc 模式，提供更好的網路隔離
  requires_compatibilities = ["EC2"]  # 指定使用 EC2 啟動類型

  container_definitions = jsonencode([
    {
      name  = "my-app-container"
      image = "${aws_ecr_repository.app_ecr.repository_url}:${var.image_tag}" # 引用 ECR 映像檔和傳入的 image_tag
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
  cluster_arn     = aws_ecs_cluster.my_ec2_cluster.arn
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1 # 你希望運行的任務實例數量

  launch_type = "EC2" # *** 指定為 EC2 啟動類型 ***

  # 由於 Task Definition 使用了 awsvpc 網路模式，這裡仍然需要網路配置
  network_configuration {
    # *** 修正點 3: 將 subnets 指向 public_subnet ***
    subnets         = [aws_subnet.public_subnet.id]
    security_groups = [aws_security_group.app_sg.id]
    # *** 修正點 4: 讓 ECS 任務自動獲取公有 IP ***
    assign_public_ip = true
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
