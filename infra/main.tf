module "network" {
  source = "git::ssh://git@gitlab.digitaltolk.net/dtolk/dope/terraform-aws-network.git"
}

data "aws_kms_alias" "main" {
  name = "alias/${terraform.workspace}/main"
}

data "cloudflare_zone" "digitaltolknet" {
  name = "digitaltolk.net"
}

variable "chatwoot_domain" {
  type    = string
  default = "helpdesk.digitaltolk.net"
}

locals {
  environment = {
    LOG_LEVEL                 = "warn"
    SMTP_ADDRESS              = "email-smtp.eu-north-1.amazonaws.com"
    SMTP_PORT                 = "587"
    SMTP_ENABLE_STARTTLS_AUTO = "true"
    SMTP_AUTHENTICATION       = "plain"
    SMTP_FROM_EMAIL           = "chatwoot@digitaltolk.net"
    SMTP_REPLY_EMAIL          = "chatwoot@digitaltolk.net"
    MAILER_SENDER_EMAIL       = "chatwoot@digitaltolk.net"
    RAILS_ENV                 = "production"
    DEFAULT_LOCALE            = "en"
    POSTGRES_HOST             = module.postgres.endpoint
    POSTGRES_PORT             = "5432"
    POSTGRES_DATABASE         = module.postgres.database_name
    FRONTEND_URL              = "https://${var.chatwoot_domain}"
    REDIS_URL                 = "redis://${module.redis.nodes_address}:6379"
    DEFAULT_REGION            = var.aws_region
    ACTIVE_STORAGE_SERVICE    = "amazon"
    S3_BUCKET_NAME            = module.bucket.bucket_name
    DIRECT_UPLOADS_ENABLED    = "true"

    RAILS_MAX_THREADS   = "10"
    WEB_CONCURRENCY     = "2"
    SIDEKIQ_CONCURRENCY = "10"
  }
}
