variable "aws_profile" {
  type    = string
  default = "hub2you"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project" {
  type    = string
  default = "chatwoot-autonomia"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "domain_name" {
  type    = string
  default = "chat.hub2you.ai"
}

variable "certificate_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:354307071110:certificate/REPLACE_ME"

  validation {
    condition     = can(regex("^arn:aws:acm:[a-z0-9-]+:[0-9]{12}:certificate/.+", var.certificate_arn))
    error_message = "certificate_arn must be an issued ACM certificate ARN in the target AWS account and region."
  }
}

variable "existing_vpc_id" {
  type        = string
  description = "Existing VPC ID to reuse in the hub2you account."
  default     = "vpc-0dc630d9b0d30e44e"
}

variable "existing_public_subnet_ids" {
  type        = list(string)
  description = "Existing public subnet IDs for the public ALB."
  default = [
    "subnet-041dbb033a963d944",
    "subnet-0abaaca39d84be6db",
    "subnet-0ebfac35430c63a85"
  ]
}

variable "existing_database_subnet_ids" {
  type        = list(string)
  description = "Existing subnet IDs for RDS and ElastiCache subnet groups. In the current hub2you account these are public default subnets, while RDS remains publicly_accessible=false."
  default = [
    "subnet-041dbb033a963d944",
    "subnet-0abaaca39d84be6db",
    "subnet-0ebfac35430c63a85"
  ]
}

variable "existing_ec2_subnet_id" {
  type        = string
  description = "Existing subnet ID for the Chatwoot EC2 instance. Empty uses the first public subnet."
  default     = ""
}

variable "rds_backup_retention_period" {
  type        = number
  description = "RDS automated backup retention in days. hub2you Free Tier currently rejects 7 days, so keep 0 unless the account plan changes."
  default     = 0
}

variable "github_repo_url" {
  type    = string
  default = "https://github.com/autonom-ia/chat.git"
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "github_actions_repository" {
  type    = string
  default = "autonom-ia/chat"
}

variable "github_actions_extra_repositories" {
  type    = list(string)
  default = ["noktuaio/chat", "autonom-ia2/chat"]
}

variable "image_tag" {
  type    = string
  default = "autonomia-custom-image-port-ee"
}

variable "cw_edition" {
  type    = string
  default = "ee"
}

variable "enable_account_signup" {
  type    = bool
  default = true
}

variable "campaign_import_enabled" {
  type    = bool
  default = true
}

variable "whatsapp_api_campaigns_enabled" {
  type    = bool
  default = true
}

variable "crm_kanban_enabled" {
  type    = bool
  default = true
}

variable "crm_ai_enabled" {
  type    = bool
  default = true
}

variable "crm_ai_media_enabled" {
  type    = bool
  default = true
}

variable "autonomia_agents_enabled" {
  type    = bool
  default = true
}

variable "autonomia_agents_global" {
  type    = bool
  default = true
}

variable "autonomia_sso_enabled" {
  type    = bool
  default = true
}

variable "autonomia_sso_auto_redirect" {
  type    = bool
  default = true
}

variable "autonomia_auth_issuer" {
  type    = string
  default = "https://auth.autonomia.site"
}

variable "autonomia_auth_token_endpoint" {
  type    = string
  default = "https://auth.api-autonomia.com/oauth/token"
}

variable "autonomia_auth_context_endpoint" {
  type    = string
  default = "https://auth.api-autonomia.com/me/context"
}

variable "autonomia_financial_api_base_url" {
  type    = string
  default = "https://financial.api-autonomia.com"
}

variable "autonomia_auth_client_id" {
  type    = string
  default = "chat2you"
}

variable "email_campaign_enabled" {
  type    = bool
  default = true
}

variable "email_campaign_aws_region" {
  type    = string
  default = "us-east-1"
}

variable "email_campaign_aws_access_key_id" {
  type      = string
  default   = ""
  sensitive = true
}

variable "email_campaign_aws_secret_access_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "waha_api_url" {
  type    = string
  default = "https://wa-hub.autonomia.site"
}

variable "waha_public_url" {
  type    = string
  default = "https://wa-hub.autonomia.site"
}

variable "waha_api_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "waha_chatwoot_webhook_path" {
  type    = string
  default = "/webhooks/chatwoot"
}

variable "mailer_sender_email" {
  type    = string
  default = "no-reply@autonomia.site"
}

variable "smtp_address" {
  type    = string
  default = ""
}

variable "smtp_username" {
  type      = string
  default   = ""
  sensitive = true
}

variable "smtp_password" {
  type      = string
  default   = ""
  sensitive = true
}

variable "ec2_instance_type" {
  type    = string
  default = "t3.small"
}
