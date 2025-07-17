terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "ecs-service/${terraform.workspace}/terraform.tfstate"
    region = "ap-northeast-1"
  }
}

provider "aws" {
  region     = "ap-northeast-1"

  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

