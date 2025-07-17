# 同前述 ecs_task_definition 與 ecs_service 配置


terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-northeast-1"
}

variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
}

# 替換為你的 ECR 路徑與映像名稱
locals {
  ecr_image = "123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/my-app:${var.image_tag}"
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "my-app-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "my-app"
      image     = local.ecr_image
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "app_service" {
  name            = "my-app-service"
  cluster         = "my-ecs-cluster"        # ← 這裡填入你的 ECS Cluster 名稱
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets         = ["subnet-abc123", "subnet-def456"]  # ← 替換為你的 VPC 子網路
    security_groups = ["sg-12345678"]                      # ← 替換為你的安全群組
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
}
