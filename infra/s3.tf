module "bucket" {
  source = "git@gitlab.digitaltolk.net:dtolk/dope/terraform-aws-s3-bucket.git"
  name   = "files"

  cors_allowed_origins = ["https://${var.chatwoot_domain}"]
}
