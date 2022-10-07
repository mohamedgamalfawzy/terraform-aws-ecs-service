# IAM
#TODO: this is an output of a resource that doesn't seem to exist...  I wonder if this needs to be outputted, or needs to be there at all.

output "tf_aws_iam_service_role" {
  description = "Service linked role for the ECS service"
  value       = length(aws_iam_role.ecs_service) > 0 ? aws_iam_role.ecs_service[0] : null
}

# ECR
output "tf_aws_ecr_repository" {
  description = "ECR repository"
  value = length(aws_ecr_repository.repo) > 0 ? {
    repo = aws_ecr_repository.repo.*
  } : null
}
output "tf_aws_ecr_lifecycle_policy" {
  description = "ECR lifecycle policy"
  value = length(aws_ecr_lifecycle_policy.policy) > 0 ? {
    policy = aws_ecr_lifecycle_policy.policy.*
  } : null
}

# Service
output "tf_aws_ecs_service" {
  description = "ECS service"
  value = length(aws_ecs_service.service) > 0 ? {
    service = aws_ecs_service.service.*
  } : null
}

# Task
output "tf_aws_ecs_task_definition" {
  description = "ECS task definition"
  value = length(aws_ecs_task_definition.task) > 0 ? {
    task = aws_ecs_task_definition.task.*
  } : null
}