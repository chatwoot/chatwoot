resource "aws_ecr_repository" "chatwoot" {

  name = local.system_name
}

resource "aws_ecr_repository" "chatwoot-sidekiq" {

  name = "${local.system_name}-sidekiq"
}
