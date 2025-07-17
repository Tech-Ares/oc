# iam.tf

# 資源：IAM 角色 (用於 ECS 容器實例)
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecs-instance-role-${var.aws_region}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name = "ecs-instance-role"
  }
}

# 資源：IAM 策略附著 (將 AWS 託管策略附著到 ECS 容器實例角色)
resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# 資源：IAM 實例設定檔 (Instance Profile，用於將 IAM 角色分配給 EC2 實例)
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecs-instance-profile-${var.aws_region}"
  role = aws_iam_role.ecs_instance_role.name
}

# 資源：IAM 角色 (用於 ECS 任務執行)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-task-execution-role-${var.aws_region}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name = "ecs-task-execution-role"
  }
}

# 資源：IAM 策略附著 (將 AWS 託管策略附著到 ECS 任務執行角色)
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 可選：IAM 角色 (用於 ECS 任務本身，如果你的應用程式需要訪問其他 AWS 服務)
/*
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role-${var.aws_region}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
  tags = {
    Name = "ecs-task-role"
  }
}

# 範例：如果應用程式需要 S3 讀取權限
resource "aws_iam_role_policy_attachment" "ecs_task_s3_read_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
*/
