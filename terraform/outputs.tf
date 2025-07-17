# outputs.tf

output "ecs_cluster_name" {
  description = "ECS 叢集名稱"
  value       = aws_ecs_cluster.my_ec2_cluster.name
}

output "ecs_service_name" {
  description = "ECS 服務名稱"
  value       = aws_ecs_service.app_service.name
}

output "ecr_repository_url" {
  description = "ECR 儲存庫 URL"
  # 修正點：將 aws_ecr_repository.app_ecr 改為 data.aws_ecr_repository.app_ecr
  value       = data.aws_ecr_repository.app_ecr.repository_url
}

output "ecs_task_definition_arn" {
  description = "ECS 任務定義 ARN"
  value       = aws_ecs_task_definition.app_task.arn
}

output "ecs_container_instance_id" {
  description = "ECS 容器實例 ID"
  value       = aws_instance.ecs_container_instance.id
}
