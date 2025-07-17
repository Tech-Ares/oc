terraform {
  required_version = ">= 1.0.0" # 根據你的 Terraform CLI 版本調整
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # 根據你的需求選擇適合的 AWS 供應商版本
    }
  }

  # 後端設定：用於儲存 Terraform 狀態檔案 (tfstate)
  # 這裡的設定會被 GitHub Actions 中的 -backend-config 覆寫
  # 但為了本地開發或預設值，保留此處
  backend "s3" {
    bucket = "s56405112" # 替換為你的 S3 儲存桶名稱
    key    = "my_project.tfstate" # 替換為你的狀態檔案路徑和名稱
    region = "ap-northeast-1" # 替換為你的 S3 儲存桶所在區域
    encrypt = true # 建議啟用加密
  }
}

provider "aws" {
  region = var.aws_region # 從 variables.tf 中獲取區域變數

  # 注意：在 CI/CD 中，AWS 憑證通常由 aws-actions/configure-aws-credentials 處理
  # 這裡如果你的 GitHub Actions 透過 -var 傳入，則需要定義
  # 但更推薦的方式是讓 configure-aws_credentials 設定環境變數，Terraform 會自動讀取
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
}
