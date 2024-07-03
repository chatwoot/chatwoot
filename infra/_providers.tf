# 💥
# 💥 FILE WILL BE OVERWRITTEN
# 💥

terraform {
  required_version = "1.5.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.56.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.36.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "2.4.2"
    }

    dns = {
      source  = "hashicorp/dns"
      version = "3.4.1"
    }

    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }

    time = {
      source  = "hashicorp/time"
      version = "0.11.2"
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
