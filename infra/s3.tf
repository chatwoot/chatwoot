module "bucket" {
  source = "git@gitlab.digitaltolk.net:dtolk/dope/terraform-aws-s3-bucket.git"
  name   = "files"

  cors_allowed_origins = ["https://${var.chatwoot_domain}"]

  versioning                           = true
  lifecycle_noncurrent_expiration_days = 90
}

module "exports_bucket" {
  source = "git@gitlab.digitaltolk.net:dtolk/dope/terraform-aws-s3-bucket.git"
  name   = "exports"
}

data "aws_iam_policy_document" "task_policy" {
  statement {
    actions = [
      "s3:*",
    ]

    resources = ["${module.bucket.bucket_arn}/*", "${module.exports_bucket.bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "task_access_policy" {
  name        = "${local.system_name}-task-s3"
  description = "${local.system_name}-task-s3"
  policy      = data.aws_iam_policy_document.task_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = module.service.task_role_name
  policy_arn = aws_iam_policy.task_access_policy.arn
}
