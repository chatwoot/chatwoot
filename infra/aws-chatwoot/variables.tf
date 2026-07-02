variable "aws_profile" {
  type    = string
  default = "default"
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
  default = "agents.autonomia.site"
}

variable "certificate_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:140023375763:certificate/cee74474-da0c-4aba-b9f7-3759e4eddd7e"
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
  default = false
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
  default = "talkai"
}

variable "email_campaign_enabled" {
  type    = bool
  default = false
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
  default = "https://wa-autonomia.autonomia.site"
}

variable "waha_public_url" {
  type    = string
  default = "https://wa-autonomia.autonomia.site"
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
