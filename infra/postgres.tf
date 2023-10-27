module "postgres" {
  source                 = "git@gitlab.digitaltolk.net:dtolk/dope/terraform-aws-db.git"
  name                   = local.system_name
  engine                 = "postgres"
  engine_version         = "15.4"
  parameter_group_family = "postgres15"
  db_port                = 5432
  db_name                = "outline"
}

resource "aws_security_group_rule" "postgres" {
  type      = "ingress"
  from_port = 5432
  to_port   = 5432
  protocol  = "tcp"

  source_security_group_id = module.service.security_group_id
  security_group_id        = module.postgres.security_group_id
}

resource "aws_security_group_rule" "sidekiq_postgres" {
  type      = "ingress"
  from_port = 5432
  to_port   = 5432
  protocol  = "tcp"

  source_security_group_id = module.service-sidekiq.security_group_id
  security_group_id        = module.postgres.security_group_id
}
