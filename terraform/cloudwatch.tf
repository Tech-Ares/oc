# cloudwatch.tf

# 資源：CloudWatch 日誌組 (用於收集 ECS 任務日誌)
resource "aws_cloudwatch_log_group" "app_log_group" {
  name              = "/ecs/my-app-${var.aws_region}" # 與 Task Definition 中 logConfiguration 的 awslogs-group 匹配
  retention_in_days = 7             # 日誌保留天數，根據需求調整
  tags = {
    Name = "my-app-log-group"
  }
}
