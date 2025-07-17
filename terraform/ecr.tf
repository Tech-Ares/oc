# ecr.tf

# 資源：ECR 儲存庫 (用於存放 Docker 映像檔)
resource "aws_ecr_repository" "app_ecr" {
  name                 = var.ecr_repo_name # 從 variables.tf 中獲取 ECR 儲存庫名稱
  image_tag_mutability = "MUTABLE" # 允許標籤覆寫，或者設為 IMMUTABLE 以確保標籤唯一性
  image_scanning_configuration {
    scan_on_push = true # 啟用映像檔推送時掃描
  }
  tags = {
    Name = "my-app-ecr-repository-${var.aws_region}"
  }
}
