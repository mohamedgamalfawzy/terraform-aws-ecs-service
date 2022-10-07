locals {
  port_mappings_by_network_mode = {
    bridge = [
      {
        containerPort = var.port
        hostPort      = 0 ###dynamic
        protocol      = var.task_protocol
      }]
    awsvpc = [
      {
        containerPort = var.port
        hostPort      = var.port
        protocol      = var.task_protocol
      }]
    host = [
      {
        containerPort = var.port
        hostPort      = var.port
        protocol      = var.task_protocol
      }]
  }
}
# TODO: TF 0.13, we can make this conditional, see:
# TODO https://github.com/hashicorp/terraform/issues/17519
module "container_definition" {
  source  = "app.terraform.io/cloudwss/ecs-container-defination/aws"
  version = "1.0.4"
  #  source               = "../terraform-aws-ecs-container-definition" ## Debug
  container_name               = var.name
  container_image_base         = var.enable_repo == true ? aws_ecr_repository.repo[0].repository_url : var.task_image
  container_image_tag          = var.task_image_tag
  container_cpu                = var.app_container_cpu_reservation
  container_memory_reservation = var.app_container_memory_reservation
  container_memory             = var.app_container_memory_reservation
  log_configuration            = var.task_log_configuration
  docker_labels                = var.app_container_docker_labels
  ulimits                      = var.ulimits
  mount_points                 = var.mount_points
  environment = [for name, value in var.task_env_vars : {
    name  = name
    value = value
  }]
  secrets = [for name, valueFrom in var.task_secrets : {
    name      = name
    valueFrom = valueFrom
  }]
  port_mappings = concat(local.port_mappings_by_network_mode[var.network_mode], var.task_additional_port_mappings)
}

resource "aws_ecs_task_definition" "task" {
  count                    = var.enable_task ? 1 : 0
  # this joins the above container defintion together with additional optional
  # sidecar definitions. concat creates a list out of the sidecar definitions
  # passed into the module and the above definition, join turns it to string
  container_definitions    = "[${join(", ", concat([module.container_definition.json_map], var.task_sidecar_container_definitions))}]"
  cpu                      = var.task_cpu_hard_limit
  ##TODO If fargate we need to add all the soft cpu requirements of the container and set this
  execution_role_arn       = var.task_execution_role_arn
  family                   = "${var.name}_task"
  memory                   = var.task_memory_limit
  ##TODO If fargate we need to add up all the soft memory requirements of the containers and set this
  network_mode             = var.network_mode
  requires_compatibilities = var.service_launch_type == "FARGATE" ? concat([
    "FARGATE"
  ], var.task_compatibilities) : concat(["EC2"], var.task_compatibilities)
  tags                     = var.tags
  task_role_arn            = var.task_role_arn

  dynamic "volume" {
    for_each = var.volume
    content {
      name      = volume.value.name
      host_path = lookup(volume.value, "host_path", null)

      dynamic "docker_volume_configuration" {
        for_each = lookup(volume.value, "docker_volume_configuration", [])
        content {
          scope         = lookup(docker_volume_configuration.value, "scope", null)
          autoprovision = lookup(docker_volume_configuration.value, "autoprovision", null)
          driver        = lookup(docker_volume_configuration.value, "driver", null)
          driver_opts   = lookup(docker_volume_configuration.value, "driver_opts", null)
          labels        = lookup(docker_volume_configuration.value, "labels", null)
        }
      }

      dynamic "efs_volume_configuration" {
        for_each = lookup(volume.value, "efs_volume_configuration", [])
        content {
          file_system_id          = lookup(efs_volume_configuration.value, "file_system_id", null)
          root_directory          = lookup(efs_volume_configuration.value, "root_directory", null)
          transit_encryption      = lookup(efs_volume_configuration.value, "transit_encryption", null)
          transit_encryption_port = lookup(efs_volume_configuration.value, "transit_encryption_port", null)
        }
      }
    }
  }
}