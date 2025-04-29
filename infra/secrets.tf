resource "random_password" "secret_key_base" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "azure_id" {
  name  = "/${terraform.workspace}/${local.system_name}/AZURE_CLIENT_ID"
  type  = "SecureString"
  value = "bar"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "azure_secret" {
  name  = "/${terraform.workspace}/${local.system_name}/AZURE_CLIENT_SECRET"
  type  = "SecureString"
  value = "bar"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "azure_tenant_id" {
  name  = "/${terraform.workspace}/${local.system_name}/AZURE_TENANT_ID"
  type  = "SecureString"
  value = "bar"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "secret_key_base" {
  name  = "/${terraform.workspace}/${local.system_name}/SECRET_KEY_BASE"
  type  = "SecureString"
  value = random_password.secret_key_base.result

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "main" {
  for_each = toset(["SMTP_USERNAME", "SMTP_PASSWORD"])

  name  = "/${terraform.workspace}/${local.system_name}/${each.key}"
  type  = "SecureString"
  value = "bar"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "dt_client_id" {
  name  = "/${terraform.workspace}/${local.system_name}/DT_CLIENT_ID"
  type  = "SecureString"
  value = "bar"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "dt_client_secret" {
  name  = "/${terraform.workspace}/${local.system_name}/DT_CLIENT_SECRET"
  type  = "SecureString"
  value = "bar"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "dt_admin_password" {
  name  = "/${terraform.workspace}/${local.system_name}/DT_ADMIN_PASSWORD"
  type  = "SecureString"
  value = "bar"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "dt_tenant_uuid" {
  name  = "/${terraform.workspace}/${local.system_name}/DT_TENANT_UUID"
  type  = "SecureString"
  value = "bar"

  lifecycle {
    ignore_changes = [value]
  }
}
