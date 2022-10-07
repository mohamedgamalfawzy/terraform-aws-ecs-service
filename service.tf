# ECS service
resource "aws_ecs_service" "service" {
  count                             = var.enable_service ? 1 : 0
  cluster                           = var.service_cluster_id
  desired_count                     = var.service_desired_count
  health_check_grace_period_seconds = var.service_grace_period
  iam_role                          = var.network_mode != "awsvpc" ? aws_iam_role.ecs_service[0].arn : null
  launch_type                       = var.service_launch_type
  name                              = var.name
  scheduling_strategy               = var.service_scheduling_strategy
  tags                              = var.tags
  task_definition                   = var.enable_task ? aws_ecs_task_definition.task[0].arn : var.service_task_definition_arn
  enable_execute_command            = var.enable_execute_command
  # this is only needed for EC2
  dynamic "ordered_placement_strategy" {
    for_each = var.service_launch_type == "EC2" ? var.ordered_placement_strategy : []
    content {
      field = lookup(ordered_placement_strategy.value, "field", null)
      type  = lookup(ordered_placement_strategy.value, "type", null)
    }
  }

  # this is only needed by awsvpc network mode
  dynamic "network_configuration" {
    for_each = var.network_mode == "awsvpc" ? [1] : []
    content {
      security_groups  = var.service_security_group_ids
      subnets          = var.service_subnet_ids
      assign_public_ip = var.service_assign_public_ip
    }
  }

  load_balancer {
    container_name   = var.name
    container_port   = var.port
    target_group_arn = var.service_target_group_arn
  }

  deployment_circuit_breaker {
    enable   = var.circuit_breaker_deployment_enabled
    rollback = var.circuit_breaker_rollback_enabled
  }
}