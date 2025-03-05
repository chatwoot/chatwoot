# 💥
# 💥 FILE WILL BE OVERWRITTEN
# 💥

terraform {
  required_version = "1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.87.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.1.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "2.7.0"
    }

    dns = {
      source  = "hashicorp/dns"
      version = "3.4.2"
    }

    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }

    time = {
      source  = "hashicorp/time"
      version = "0.12.1"
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
