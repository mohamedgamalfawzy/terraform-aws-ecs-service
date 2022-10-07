resource "aws_ecr_repository" "repo" {
  count = var.enable_repo ? 1 : 0
  name  = var.repo_path
  tags  = var.tags

  image_scanning_configuration {
    scan_on_push = var.repo_scan_on_push
  }
  # TODO: add lifecycle rules.
  # you cannot use variables in lifecycle blocks. See:
  # https://github.com/hashicorp/terraform/issues/3116
}

resource "aws_ecr_lifecycle_policy" "policy" {
  count      = var.enable_repo && var.repo_lifecycle_policy != null ? 1 : 0
  repository = aws_ecr_repository.repo[0].name
  policy     = var.repo_lifecycle_policy
}