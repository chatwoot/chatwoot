module "postgres" {
  source                 = "git@gitlab.digitaltolk.net:dtolk/dope/terraform-aws-db.git"
  name                   = local.system_name
  instance_class         = "db.t4g.medium"
  engine                 = "postgres"
  engine_version         = "15.5"
  parameter_group_family = "postgres15"
  db_port                = 5432
  db_name                = "outline"
  multi_az               = true
  apply_immediately      = true
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

data "aws_security_group" "bastion" {
  vpc_id = module.network.main_vpc_id
  tags = {
    System = "bastion"
    Env    = local.system_env
  }
}
