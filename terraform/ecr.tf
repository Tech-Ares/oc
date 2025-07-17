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

# 關於 "RepositoryAlreadyExistsException" 錯誤的說明：
# 如果你遇到這個錯誤，表示名為 'my-app' 的 ECR 儲存庫已經存在於你的 AWS 帳戶中，
# 但 Terraform 的狀態檔案中沒有記錄它。
# 解決方法是：
# 1. 如果這個儲存庫不應該由 Terraform 管理，你可以手動刪除它 (請謹慎操作，確保沒有其他依賴)。
# 2. 如果這個儲存庫應該由 Terraform 管理，你需要將它導入到當前工作區的 Terraform 狀態中。
#    你需要在命令行執行一次 'terraform import' 命令：
#    terraform import aws_ecr_repository.app_ecr <你的AWS帳戶ID>.dkr.ecr.<你的區域>.amazonaws.com/my-app
#    例如：terraform import aws_ecr_repository.app_ecr 123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/my-app
#    執行 import 後，再次運行 terraform plan，應該會顯示沒有任何變更。
