module "container" {
  source = "git@gitlab.digitaltolk.net:dtolk/dope/terraform-aws-ecs-container.git"
  name   = "main"
  image  = "178432136258.dkr.ecr.eu-north-1.amazonaws.com/${local.system_name}:${var.docker_image_tag}"

  cpu    = 512
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

  health_check = {
    command      = "wget -q --spider --proxy=off 127.0.0.1:3000/api || exit 1"
    interval     = 45
    start_period = 90
    timeout      = 10
  }
}

module "service" {
  source = "git@gitlab.digitaltolk.net:dtolk/dope/terraform-aws-ecs-service.git"

  container_definitions = [module.container.definition]

  name         = local.system_name
  listen_hosts = [var.chatwoot_domain]

  service_port = 3000

  cpu_architecture = "X86_64"
  service_cpu      = 512
  service_memory   = 2048

  service_count_desired  = 1
  service_count_min      = 1
  service_count_max      = 6
  scale_target_value_cpu = 33

  health_check = {
    path     = "/robots.txt"
    interval = 30
    timeout  = 10
  }

  # avoids pressure on puma killing containers
  health_check_grace_period_seconds = 2147483647
}
