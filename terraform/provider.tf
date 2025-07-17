# provider.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # 建議指定明確版本，例如 "5.x.x"
    }
  }

  # 後端設定：用於儲存 Terraform 狀態檔案 (tfstate)
  # 這裡的設定會被 GitHub Actions 中的 -backend-config 覆寫
  # 但為了本地開發或預設值，保留此處
  backend "s3" {
    bucket = "s56405112"
    key    = "ecs-service/terraform.tfstate" # 修正為靜態路徑
    region = "ap-northeast-1"
    encrypt = true # 建議啟用加密
  }
}

# 預設的 AWS 供應商配置
# 這應該是整個專案中唯一一個沒有 alias 的 "aws" provider 區塊
provider "aws" {
  region = var.aws_region # 從 variables.tf 中獲取區域變數
  # 如果你的 GitHub Actions 是透過 -var 傳入 AWS 憑證，
  # 且 provider 區塊需要明確指定 access_key 和 secret_key，則取消註解以下兩行：
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
  # 但更推薦的方式是讓 configure-aws-credentials 設定環境變數，Terraform 會自動讀取。
}
