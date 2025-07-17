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

# 由於你的 GitHub Actions 工作流程明確透過 -var 傳入 AWS 憑證，這裡必須定義這些變數
# 雖然 configure-aws-credentials 動作會設定環境變數，但為了與你的 workflow 匹配，這裡保留
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
