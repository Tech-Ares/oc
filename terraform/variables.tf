# variables.tf

variable "aws_region" {
  description = "AWS 部署區域"
  type        = string
  default     = "ap-northeast-1" # 預設區域，與 GitHub Actions 中的 env.AWS_REGION 匹配
}

variable "image_tag" {
  description = "要部署的 Docker 映像檔標籤 (例如 Git SHA)"
  type        = string
}

variable "aws_access_key" {
  description = "AWS Access Key ID (敏感資訊)"
  type        = string
  sensitive   = true # 標記為敏感資訊，避免在日誌中顯示
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key (敏感資訊)"
  type        = string
  sensitive   = true # 標記為敏感資訊
}

variable "ecr_repo_name" {
  description = "ECR 儲存庫名稱"
  type        = string
  default     = "my-app" # 與 GitHub Actions 中的 env.ECR_REPO_NAME 匹配
}
