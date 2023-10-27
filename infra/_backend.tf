# 💥
# 💥 FILE WILL BE OVERWRITTEN
# 💥

terraform {
  backend "s3" {
    bucket         = "dt-infra-eu-north-1-tf-state-statefiles"
    key            = "chatwoot/terraform.tfstate"
    region         = "eu-north-1"
    profile        = "dt-infra"
    encrypt        = true
    dynamodb_table = "tf-state-lock"
    max_retries    = 10
  }
}

locals {
  system_name  = "chatwoot"
  system_owner = "platform-engineering"
  system_repo  = "dtolk/dope/chatwoot"
}
