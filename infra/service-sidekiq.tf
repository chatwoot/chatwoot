module "container-sidekiq" {
  source = "git@gitlab.digitaltolk.net:dtolk/dope/terraform-aws-ecs-container.git"
  name   = "sidekiq"
  image  = "178432136258.dkr.ecr.eu-north-1.amazonaws.com/${local.system_name}:${var.docker_image_tag}"

  cpu    = 512
  memory = 1024

  publish = [3000]

  command = ["bundle", "exec", "sidekiq -C config/sidekiq.yml"]

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
    command      = "ps aux | grep '[s]idekiq' || false"
    interval     = 45
    start_period = 90
    timeout      = 10
  }
}

module "service-sidekiq" {
  source = "git@gitlab.digitaltolk.net:dtolk/dope/terraform-aws-ecs-service.git"

  container_definitions = [module.container-sidekiq.definition]

  name = "${local.system_name}-sidekiq"

  cpu_architecture = "X86_64"
  service_cpu      = 512
  service_memory   = 1024

  service_count_desired  = 1
  service_count_min      = 1
  service_count_max      = 6
  scale_target_value_cpu = 80
}
