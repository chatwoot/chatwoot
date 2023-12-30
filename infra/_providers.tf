# 💥
# 💥 FILE WILL BE OVERWRITTEN
# 💥

terraform {
  required_version = "1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.30.0"
    }

    oci = {
      source  = "oracle/oci"
      version = "5.22.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.20.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "2.4.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = local.tags
  }
}

provider "cloudflare" {
}
