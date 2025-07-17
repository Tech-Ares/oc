# ecr.tf

# 將 'resource' 改為 'data'
data "aws_ecr_repository" "app_ecr" {
  name = var.ecr_repo_name # 引用 ECR 儲存庫的名稱
}

# 說明：
# 如果你使用 'data' 區塊，Terraform 將不會嘗試創建這個 ECR 儲存庫。
# 它只會查詢一個名為 'my-app' 的現有儲存庫並獲取其資訊。
# 這解決了 'RepositoryAlreadyExistsException' 錯誤，因為 Terraform 不再嘗試創建它。
#
# 重要提示：
# 使用 'data' 區塊意味著這個 ECR 儲存庫必須在 Terraform 運行之前就已經存在。
# 如果它不存在，Terraform 將會報錯 'NotFoundException'。
#
# 如果你希望 Terraform 在儲存庫不存在時創建它，在存在時則使用現有的，
# 這會需要更複雜的條件邏輯，通常不推薦用於簡單的 CI/CD 流程，
# 並且 'terraform import' 是處理這種情況最直接且官方推薦的方法。
