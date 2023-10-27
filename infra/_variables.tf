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

  tags = {
    Env    = terraform.workspace
    System = local.system_name
    Owner  = local.system_owner
    Repo   = local.system_repo
  }
}
