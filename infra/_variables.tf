# 💥
# 💥 FILE WILL BE OVERWRITTEN
# 💥

variable "aws_region" {
  type    = string
  default = "eu-north-1"
}

variable "aws_profile" {
  type = string
}

variable "system_tenant" {
  type    = string
  default = null
}

variable "system_type" {
  type    = string
  default = null
}

variable "system_env" {
  type    = string
  default = null
}

variable "system_region" {
  type    = string
  default = null
}

variable "docker_image_tag" {
  type    = string
  default = "latest"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

locals {
  aws_current_account_id = data.aws_caller_identity.current.account_id
  aws_current_region     = data.aws_region.current.name
  system_env             = var.system_env != null ? var.system_env : terraform.workspace

  tags = {
    Env       = local.system_env
    Workspace = terraform.workspace
    System    = local.system_name
    Owner     = local.system_owner
    Repo      = local.system_repo
    Type      = var.system_type
    Tenant    = var.system_tenant
  }
}
