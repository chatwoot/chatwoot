module "network" {
  source = "git::ssh://git@gitlab.digitaltolk.net/dtolk/dope/terraform-aws-network.git"
}

data "aws_kms_alias" "main" {
  name = "alias/${terraform.workspace}/main"
}

data "cloudflare_ip_ranges" "all" {
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
    MAILER_SENDER_EMAIL       = "Helpdesk <help@digitaltolk.se>"
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
    S3_EXPORT_BUCKET_NAME     = module.exports_bucket.bucket_name
    DIRECT_UPLOADS_ENABLED    = "true"
    DT_LLM_HUB_URL            = "https://api-gateway.digitaltolk.se"
    DT_LLM_HUB_API_VERSION    = "api/v3/llm-hub"
    DT_ADMIN_USERNAME         = "engineering+chatwoot@digitaltolk.com"
    AGENT_BOT_EMAIL           = "dt-automate@digitaltolk.com"
    RAILS_MAX_THREADS         = "10"
    WEB_CONCURRENCY           = "2"
    SIDEKIQ_CONCURRENCY       = "10"

    RACK_ATTACK_LIMIT             = "1024"
    ENABLE_RACK_ATTACK_WIDGET_API = "false"
    TRUSTED_PROXY_IPS             = "10.0.0.0/8,172.16.0.0/12,192.168.0.0/16,${join(",", concat(data.cloudflare_ip_ranges.all.ipv4_cidrs, data.cloudflare_ip_ranges.all.ipv6_cidrs))}"
  }
}
