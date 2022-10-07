# we cannot use aws_iam_service_linked_role here because it leads to duplicates
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_service" {
  count              = var.enable_service && var.network_mode != "awsvpc" ? 1 : 0
  name_prefix        = "ecs_service"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags               = merge({ Name = "${var.name}_ecs_service_role" }, var.tags)
  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.account.account_id}:policy/base/domain-admin"
}

data "aws_iam_policy_document" "ecs_service_role" {
  count = var.enable_service && var.network_mode != "awsvpc" ? 1 : 0
  statement { ## See https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-legacy-iam-roles.html
    sid = "ServiceScheduler"
    actions = ["ec2:AuthorizeSecurityGroupIngress",
      "ec2:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ecs_service_role" {
  count       = var.enable_service && var.network_mode != "awsvpc" ? 1 : 0
  policy      = data.aws_iam_policy_document.ecs_service_role[0].json
  name_prefix = "ecs_elb"
}

resource "aws_iam_role_policy_attachment" "ecs_service_role_attachment" {
  count      = var.enable_service && var.network_mode != "awsvpc" ? 1 : 0
  role       = aws_iam_role.ecs_service[0].name
  policy_arn = aws_iam_policy.ecs_service_role[0].arn
}