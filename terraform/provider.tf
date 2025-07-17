# versions.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # 建議指定明確版本
    }
  }

  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "ecs-service/terraform.tfstate" # 修正為靜態路徑
    region = "ap-northeast-1"
  }
}
