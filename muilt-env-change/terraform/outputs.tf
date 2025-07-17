output "task_definition_arn" {
  value = aws_ecs_task_definition.app_task.arn
}

output "service_name" {
  value = aws_ecs_service.app_service.name
}
