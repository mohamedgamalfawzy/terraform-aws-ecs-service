
# Feature switches
variable "enable_service" {
  description = "Enable handling ECS service creation"
  default     = false
  type        = bool
}
variable "enable_task" {
  description = "Enable handling task creation"
  default     = false
  type        = bool
}
variable "enable_repo" {
  description = "Enable handling ECR repository creation"
  default     = false
  type        = bool
}

variable "enable_execute_command" {
  type        = bool
  description = "Specifies whether to enable Amazon ECS Exec for the tasks within the service"
  default     = false
}

# Global variables. Needed for multiple resources
variable "volume" {
  description = "(Optional) A set of volume blocks that containers in your task may use. This is a list of maps, where each map should contain \"name\", \"host_path\", \"docker_volume_configuration\" and \"efs_volume_configuration\"."
  type        = list(any)
  default     = []
}

variable "ordered_placement_strategy" {
  description = "Placement strategy for the ECS service. Only used for EC2. Default spread and binpack"
  type        = list(any)
  default     = [
    {
      type = "spread"
      field = "instanceId"
    },
    {
      type = "binpack"
      field = "memory"
    }
  ]
}

variable "mount_points" {
  type = list(object({
    containerPath = string
    sourceVolume  = string
  }))
  description = "Container mount points. This is a list of maps, where each map should contain a `containerPath` and `sourceVolume`"
  default     = null
}

variable "network_mode" {
  description = "Network mode for the task. Has to be awsvpc for FARGATE. Default: awsvpc. awsvpc | bridge"
  type        = string
  validation {
    condition     = contains(["awsvpc", "bridge"], var.network_mode)
    error_message = "Allowed values are \"awsvpc|bridge\" and argument must not be null."
  }
}

variable "ulimits" {
  type = list(object({
    name      = string
    hardLimit = number
    softLimit = number
  }))
  description = "Container ulimit settings. This is a list of maps, where each map should contain \"name\", \"hardLimit\" and \"softLimit\""
  default     = null
}

variable "port" {
  description = "Internal container port that the alb connects to"
  default     = null
  type        = number
  validation {
    condition     = var.port == null || can(var.port >= 1 && var.port <= 30000)
    error_message = "The port value must be between the range of 1 and 30000. Or null."
  }
}

variable "tags" {
  description = "Tags."
  type        = map(string)
}
variable "name" {
  description = "Name of the service / task"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name))
    error_message = "The name value must contain alphanumeric characters, hyphen and digits only."
  }
}

# Task variables. Only need to be touched if enable_task = true
variable "task_secrets" {
  description = "Map of secrets for the task."
  default     = {}
  type        = map(string)
  validation {
    condition = length(var.task_secrets) == 0 || (
    can([for env_var in keys(var.task_secrets) : regex("^[A-Z0-9_]+$", env_var)]) &&
    ! can([for val in values(var.task_secrets) : regex("\\s+", val)])
    )
    error_message = "The task_secrets value must be a map with environment variable names and their values as any string. The environment variable names should contain upper-case letters, digits or underscores only. The value should not contain any whitespace characters."
  }
}
variable "task_env_vars" {
  description = "Map of environmental variables for the task."
  default     = {}
  type        = map(string)
  validation {
    condition = length(var.task_env_vars) == 0 || (
    can([for env_var in keys(var.task_env_vars) : regex("^[A-Z0-9_]+$", env_var)]) &&
    ! can([for val in values(var.task_env_vars) : regex("\\s+", val)])
    )
    error_message = "The task_env_vars value must be a map with environment variable names and their values as any string. The environment variable names should contain upper-case letters, digits or underscores only. The value should not contain any whitespace characters."
  }
}
### For more about cpu and memory settings in ecs see: https://aws.amazon.com/blogs/containers/how-amazon-ecs-manages-cpu-and-memory-resources/
variable "task_cpu_hard_limit" {
  description = "CPU for the task in VCPUS (1/1024 CPU).  This sets a hard limit for the CPU available to all containers in the task definition.  It does not reserve resources"
  default     = null
  type        = number
  validation {
    condition     = var.task_cpu_hard_limit == null || can(var.task_cpu_hard_limit >= 128 && var.task_cpu_hard_limit <= 32000)
    error_message = "The task_cpu_hard_limit value must be between 128 to 32000 or null only."
  }
}
variable "app_container_cpu_reservation" {
  description = "CPU for the application container VCPUS (1/1024 CPU).  This sets a soft limit/reservation of CPU for your app and helps ecs autoscale and manage headroom."
  default     = null # This could be allowed, but then we don't have any data about cpu requirements to use for scaling our cluster.
  type        = number
  validation {
    condition     = var.app_container_cpu_reservation == null || can(var.app_container_cpu_reservation >= 128 && var.app_container_cpu_reservation <= 32000)
    error_message = "The app_container_cpu_reservation value must be between 128 to 32000 or null only."
  }
}
variable "task_memory_limit" {
  description = "Memory for the task in mb.  This sets a hard limit for memory to all available containers in this task definition."
  default     = null
  type        = number
  validation {
    condition     = var.task_memory_limit == null || can(var.task_memory_limit == 0) || can(var.task_memory_limit >= 128 && var.task_memory_limit <= 128000)
    error_message = "The task_memory_limit value must be between 0 for unlimited or  128MiB to 128000MiB only."
  }
}
variable "app_container_docker_labels" {
  ## This typing really makes labels in ecs_service only useful for a specific use case.
  ## Terraform currently does not support using .'s in an object key so it's not possible create a proper typing here.
  ## https://github.com/hashicorp/terraform/issues/22681
  //type        =  object({
  //   "com.datadoghq.ad.logs" = object({
  //     service = string
  //     source = string
  //   })})*/
  type        = any
  description = "docker_labels to be set by ecs runtime and passed as a nested map which will be jsonencoded."
  default     = null
}
variable "app_container_memory_reservation" {
  description = "Memory reservation for the app container in MB.  This sets a soft limit/reservation of memory for your app and helps ecs autoscale and manage headroom."
  #default = null # This could be allowed, but then we don't have any data about memory requirements to use for scaling our cluster.
  type = number
  validation {
    condition     = var.app_container_memory_reservation == null || can(var.app_container_memory_reservation == 0) || can(var.app_container_memory_reservation >= 128 && var.app_container_memory_reservation <= 128000)
    error_message = "The app_container_memory_reservation value must be between 0 for unlimited or  128MiB to 128000MiB only."
  }
}
### End CPU and Memory
variable "task_image" {
  description = "Image to use WITHOUT tag"
  default     = null
  type        = string
  validation {
    condition     = var.task_image == null || can(regex("^[a-zA-Z0-9]+[\\w_/.-]+$", var.task_image))
    error_message = "The task_image must be null if enable_repo is true, otherwise start with letters (upper/lower case) or digits followed by any of the following characters (slash/periods/hyphen/underscore). Should be specified like dockerhub: \"nginx\"  or ecr: \"123456789012.dkr.ecr.eu-west-1.amazonaws.com/nginx\" without \":<tag>\".  Specify the tag in docker_image_tag."
  }
}
variable "task_image_tag" {
  description = "Image tag"
  default     = null
  type        = string
  validation {
    condition     = var.task_image_tag == null || can(regex("^[a-zA-Z0-9][\\w_/.-]{0,127}$", var.task_image_tag))
    error_message = "The task_image_tag should contain alphanumeric characters, periods, underscores and hyphens only. A tag name must not start with a period or a dash."
  }
}
variable "task_execution_role_arn" {
  description = "Arn of task execution role."
  default     = null
  type        = string
  validation {
    condition     = var.task_execution_role_arn == null || can(regex("^arn:(aws[a-zA-Z-]*)?:iam::\\d{12}:role/[a-zA-Z_0-9+=,.@\\-_/]+$", var.task_execution_role_arn))
    error_message = "The task_execution_role_arn value must start with arn:aws:iam::<account-number>:role/ and can only contain hypens, underscore, periods or slashes. Or null."
  }
}
variable "task_role_arn" {
  description = "Arn of the task role."
  default     = null
  type        = string
  validation {
    condition     = var.task_role_arn == null || can(regex("^arn:(aws[a-zA-Z-]*)?:iam::\\d{12}:role/[a-zA-Z_0-9+=,.@\\-_/]+$", var.task_role_arn))
    error_message = "The task_role_arn value must start with arn:aws:iam::<account-number>:role/ and can only contain hypens, underscore, periods or slashes. Or null."
  }
}
variable "task_sidecar_container_definitions" {
  description = "If you want to launch any sidecar containers, you can add additional container definitions."
  default     = []
  type        = list(string)
}
variable "task_compatibilities" {
  description = "The compatibilities FARGATE / EC2 are set automatically."
  default     = []
  type        = list(string)
}
variable "task_log_configuration" {
  description = "Task log configuration as string."
  default     = null
  #type = string ##TODO put this back when it doesn't break terraorm
}

variable "task_additional_port_mappings" {
  description = "Port mappings that should exist other than the port mapping between the app and load balancer which is automatically created."
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))
  default = []
}
variable "task_protocol" {
  description = "Protocol of the internal port used by the alb"
  default     = "tcp"
  type        = string
  validation {
    condition     = var.task_protocol == "udp" || var.task_protocol == "tcp"
    error_message = "The value of task_protocol must be one of \"tcp|udp\"."
  }
}
# ECR repo variables. Only need to be touched if enable_repo = true
variable "repo_path" {
  description = "Repository path."
  default     = null
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9]+[\\w_/.-]+$", var.repo_path)) || var.repo_path == null
    error_message = "The repo_path value must be null if enable_repo is false, otherwise start with letters (upper/lower case) or digits followed by any of the following characters (slash/periods/hyphen/underscore). Should be specified without tag."
  }
}
variable "repo_scan_on_push" {
  description = "Whether to enable automatic image vulnerability scanning. Default true."
  default     = true
  type        = bool
}
variable "repo_lifecycle_policy" {
  description = "Optional lifecycle policy for the ecr repo. For example to only keep n images."
  default     = null
  type        = string
}

# ECS Service variables. Only need to be touched if enable_service = true
variable "service_cluster_id" {
  description = "Id of the cluster the service should belong to."
  default     = null
  type        = string
  validation {
    condition = var.service_cluster_id == null || (
    can(regex("^[A-z\\d-]+$", var.service_cluster_id))) || (
    can(regex("^arn:(aws[a-zA-Z-]*)?:ecs:[a-z]{2}-[a-z]+-\\d*:\\d{12}:cluster\\/[A-z\\d-]{1,255}$", var.service_cluster_id)))
    error_message = "The service_cluster_id value must null if enable_service is false, else contain only letters (upper-case and lower-case), numbers, and hyphens, or a valid cluster arn."
  }
}
variable "service_desired_count" {
  description = "Desired task count"
  default     = null
  type        = number
}
variable "service_grace_period" {
  description = "Health check grace period when a new task is started. Default 300"
  default     = 300
  type        = number
}
variable "service_launch_type" {
  description = "Launch type for the service. Default FARGATE. EC2|FARGATE"
  default     = "FARGATE"
  type        = string
  validation {
    condition     = contains(["FARGATE", "EC2"], var.service_launch_type)
    error_message = "The service_launch_type allowed values are \"FARGATE|EC2\" and argument must not be null."
  }
}
variable "service_scheduling_strategy" {
  description = "How the containers should be spawned. Default REPLICA. REPLICA | DAEMON"
  default     = "REPLICA"
  type        = string
  validation {
    condition     = contains(["REPLICA", "DAEMON"], var.service_scheduling_strategy)
    error_message = "The service_schedulint_strategy allowed values are \"REPLICA|DAEMON\" and argument must not be null."
  }
}
variable "service_task_definition_arn" {
  description = "Arn of task definition used by the service. Only used if enable_task = false"
  default     = null
  type        = string
  validation {
    condition     = var.service_task_definition_arn == null || can(regex("^arn:(aws[a-zA-Z-]*)?:ecs:[a-z]{2}-[a-z]+-\\d*:\\d{12}:task-definition\\/[A-z\\d-]{1,255}:\\d*$", var.service_task_definition_arn))
    error_message = "The service_task_definition_arn value must be set only if enable_service is true and enable_task is false, and start with arn:aws:ecs:<region>:<account-number>:task-definition/ and can only contain Up to 255 letters (uppercase and lowercase), numbers, and hyphens."
  }
}
variable "service_target_group_arn" {
  description = "Arn of the target group that the service should register tasks in"
  default     = null
  type        = string
  validation {
    condition     = var.service_target_group_arn == null || can(regex("^arn:(aws[a-zA-Z-]*)?:elasticloadbalancing:[a-z]{2}-[a-z]+-\\d*:\\d{12}:targetgroup\\/[A-z\\d-]{1,32}/[abcdef\\d]+$", var.service_target_group_arn))
    error_message = "The service_target_group_arn value must be set only if enable_service is true, and start with arn:aws:elasticloadbalancing:<regoin>:<account-number>:targetgroup/<name>/<id> and name can only contain Up to 32 letters (uppercase and lowercase), numbers, and hyphens."
  }
}

# Only needed for EC2 launch_type
variable "service_placement_strategy_type" {
  description = "Placement strategy for the ECS service. Only used for EC2. Default spread. random | spread | binpack"
  default     = "spread"
  type        = string
  validation {
    condition     = contains(["random", "spread", "binpack"], var.service_placement_strategy_type)
    error_message = "The service_placement_strategy_type allowed values are \"random|spread|binpack\" and argument must not be null."
  }
}
variable "service_placement_strategy_field" {
  description = "Field to apply plament strategy against. Only used for EC2. Default instanceId. Please see: https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_PlacementStrategy.html"
  default     = "instanceId"
  type        = string
  # cannot have a validation here since placement_strategy_type random allows any input
}

# Only needed for FARGATE launch_type
variable "service_security_group_ids" {
  description = "Security group IDs for the container network interface. Only used for FARGATE. Default empty."
  default     = []
  type        = list(string)
}
variable "service_subnet_ids" {
  description = "Subnet IDs for the container network interface. Only used for FARGATE. Default empty."
  default     = []
  type        = list(string)
}
variable "service_assign_public_ip" {
  description = "Whether to assing a public IP to the container network interface. Only used for FARGTE. Default false."
  default     = false
  type        = bool
}

variable "circuit_breaker_deployment_enabled" {
  type        = bool
  description = "Whether to enable the deployment circuit breaker logic for the service"
  default     = true
}

variable "circuit_breaker_rollback_enabled" {
  type        = bool
  description = "Whether to enable Amazon ECS to roll back the service if a service deployment fails"
  default     = true
}