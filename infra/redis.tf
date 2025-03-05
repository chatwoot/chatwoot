module "redis" {
  source         = "git@gitlab.digitaltolk.net:dtolk/dope/terraform-aws-elasticache.git"
  name           = local.system_name
  engine_version = "7.1"

  create_subnet_group = true
}

resource "aws_security_group_rule" "ingress_cluster" {
  type      = "ingress"
  from_port = 6379
  to_port   = 6379
  protocol  = "tcp"

  source_security_group_id = module.service.security_group_id
  security_group_id        = module.redis.security_group_id
}

resource "aws_security_group_rule" "sidekiq_ingress_cluster" {
  type      = "ingress"
  from_port = 6379
  to_port   = 6379
  protocol  = "tcp"

  source_security_group_id = module.service-sidekiq.security_group_id
  security_group_id        = module.redis.security_group_id
}
