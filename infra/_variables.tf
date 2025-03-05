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
  env_suffix             = local.system_env == "prd" ? "" : "-${local.system_env}"
  system_hostname        = "${local.system_name}${local.env_suffix}"

  tags = {
    Env       = local.system_env
    Workspace = terraform.workspace
    System    = local.system_name
    Owner     = local.system_owner
    Repo      = local.system_repo
    Type      = var.system_type
    Tenant    = var.system_tenant
  }

  container_reserved_sidecar_cpu    = (32 + 32)  # dd-agent + logging
  container_reserved_sidecar_memory = (384 + 64) # dd-agent + logging

  cloudflare_zones = {
    "digitaltolk.net" = "c6c4b12c9236b18a2983919c4cfa7fdb"
    "digitaltolk.com" = "b6235349731f648cd4d0daeaad8c80c8"
    "digitaltolk.se"  = "e71feec41c3de5cfc696030a43f81b95"
    "tolk.co.uk"      = "fe23217496b8875f2ee98ffa97660baa"
    "addita.com"      = "81cce28e91ff8e9c00cec437b7e01ad0"
    "addita.se"       = "7578b28079fe7f202dbc0f080a89ac93"
    "aiconf.pk"       = "60a86859c9e7c21774016a80ad505a31"
    "bokadt.id"       = "c7b6508aa4fa736d66ab627c96911c5a"
    "digitaltolk.dk"  = "f6c9007efb2ab1f25c3eca8b2e8e0ca8"
    "digitaltolk.fi"  = "8d5fefbd9119824554c8d2c9eb0992eb"
    "digitaltolk.no"  = "8a9d882c13fe2bf6294b99692115d8f6"
    "digitaltolk.org" = "9c7b1c23b0b2c5da60f82764fc66c740"
    "genai.pk"        = "223dfeba2b111a0563834868709270ce"
    "talentemp.com"   = "be2d3ef21145e43ff629a9183b45f4f4"
    "talentemp.se"    = "03ee40dcbb51c41879dbdc74b6cf8b9d"
    "tlent.eu"        = "c0e088f4234104706d4f2438f322bd4f"
    "tolk.com"        = "210122992defe27e922d50e1af7c6083"
    "tolk.co.uk"      = "fe23217496b8875f2ee98ffa97660baa"
    "tolk.se"         = "fbb14c79a568277efd91f37f03922656"
  }
}
