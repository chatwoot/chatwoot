module "container" {
  source = "git@gitlab.digitaltolk.net:dtolk/dope/terraform-aws-ecs-container.git"
  name   = "main"
  image  = "ecr.digitaltolk.net/${local.system_repo}:${var.docker_image_tag}"

  cpu    = 256
  memory = 2048

  publish = [3000]

  # command = ["RAILS_ENV=production bundle exec rake db:migrate", "bundle exec bundle exec rails s -b 0.0.0.0 -p 3000"]

  secrets = {
    POSTGRES_USERNAME = "${module.postgres.master_user_secret_arn}:username::"
    POSTGRES_PASSWORD = "${module.postgres.master_user_secret_arn}:password::"
    SECRET_KEY_BASE   = aws_ssm_parameter.secret_key_base.arn
    SMTP_USERNAME     = aws_ssm_parameter.main["SMTP_USERNAME"].arn
    SMTP_PASSWORD     = aws_ssm_parameter.main["SMTP_PASSWORD"].arn
    AZURE_APP_ID      = aws_ssm_parameter.azure_id.arn
    AZURE_APP_SECRET  = aws_ssm_parameter.azure_secret.arn
  }

  environment = local.environment
}

module "service" {
  source = "git@gitlab.digitaltolk.net:dtolk/dope/terraform-aws-ecs-service.git"

  container_definitions = [module.container.definition]

  name         = local.system_name
  listen_hosts = [var.chatwoot_domain]

  service_port = 3000

  cpu_architecture = "X86_64"
  service_cpu      = 256
  service_memory   = 2048

  service_count_desired = 1
  service_count_min     = 1
  service_count_max     = 1

  health_check = {
    path = "/api"
  }
}
