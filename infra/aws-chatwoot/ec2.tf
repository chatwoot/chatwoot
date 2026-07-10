data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  ec2_image_uri    = "${aws_ecr_repository.chatwoot.repository_url}:${var.image_tag}"
  ecr_registry     = split("/", aws_ecr_repository.chatwoot.repository_url)[0]
  ec2_env_path     = "/chatwoot/${var.environment}/env"
  ec2_runtime_path = "/chatwoot/${var.environment}/runtime-image"
  ec2_chatwoot_env = <<-ENV
ACTIVE_STORAGE_SERVICE=amazon
AUTONOMIA_AGENTS_ENABLED=${tostring(var.autonomia_agents_enabled)}
AUTONOMIA_AGENTS_GLOBAL=${tostring(var.autonomia_agents_global)}
AUTONOMIA_AUTH_CLIENT_ID=${var.autonomia_auth_client_id}
AUTONOMIA_AUTH_CONTEXT_ENDPOINT=${var.autonomia_auth_context_endpoint}
AUTONOMIA_AUTH_ISSUER=${var.autonomia_auth_issuer}
AUTONOMIA_AUTH_REDIRECT_URI=https://${var.domain_name}/auth/autonomia/callback
AUTONOMIA_AUTH_TOKEN_ENDPOINT=${var.autonomia_auth_token_endpoint}
AUTONOMIA_FINANCIAL_API_BASE_URL=${var.autonomia_financial_api_base_url}
AUTONOMIA_SSO_AUTO_REDIRECT=${tostring(var.autonomia_sso_auto_redirect)}
AUTONOMIA_SSO_ENABLED=${tostring(var.autonomia_sso_enabled)}
AUTONOMIA_SSO_URL=/auth/autonomia
AWS_REGION=${var.aws_region}
CAMPAIGN_IMPORT_ENABLED=${tostring(var.campaign_import_enabled)}
CHATWOOT_BASE_URL=https://${var.domain_name}
CRM_AI_ENABLED=${tostring(var.crm_ai_enabled)}
CRM_AI_MEDIA_ENABLED=${tostring(var.crm_ai_media_enabled)}
CRM_KANBAN_ENABLED=${tostring(var.crm_kanban_enabled)}
CW_EDITION=${var.cw_edition}
DATABASE_URL=postgres://${aws_db_instance.chatwoot.username}:${random_password.db.result}@${aws_db_instance.chatwoot.address}:5432/${aws_db_instance.chatwoot.db_name}
EMAIL_CAMPAIGN_AWS_ACCESS_KEY_ID=${var.email_campaign_aws_access_key_id}
EMAIL_CAMPAIGN_AWS_REGION=${var.email_campaign_aws_region}
EMAIL_CAMPAIGN_AWS_SECRET_ACCESS_KEY=${var.email_campaign_aws_secret_access_key}
EMAIL_CAMPAIGN_ENABLED=${tostring(var.email_campaign_enabled)}
ENABLE_ACCOUNT_SIGNUP=${tostring(var.enable_account_signup)}
FORCE_SSL=false
FRONTEND_URL=https://${var.domain_name}
INSTALLATION_PRICING_PLAN=enterprise
INSTALLATION_PRICING_PLAN_QUANTITY=999
INSTALLATION_ENV=aws-ec2
LOG_LEVEL=info
MAILER_SENDER_EMAIL=${var.mailer_sender_email}
SIDEBAR_BACKGROUND_COLOR=#0b1e3f
POSTGRES_DATABASE=${aws_db_instance.chatwoot.db_name}
POSTGRES_HOST=${aws_db_instance.chatwoot.address}
POSTGRES_PASSWORD=${random_password.db.result}
POSTGRES_PORT=5432
POSTGRES_USERNAME=${aws_db_instance.chatwoot.username}
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
REDIS_TLS=true
REDIS_URL=rediss://:${random_password.redis.result}@${aws_elasticache_replication_group.chatwoot.primary_endpoint_address}:6379
S3_BUCKET_NAME=${aws_s3_bucket.uploads.bucket}
SECRET_KEY_BASE=${random_password.secret_key_base.result}
SMTP_ADDRESS=${var.smtp_address}
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_OPENSSL_VERIFY_MODE=none
SMTP_PASSWORD=${var.smtp_password}
SMTP_PORT=587
SMTP_USERNAME=${var.smtp_username}
WAHA_API_KEY=${var.waha_api_key}
WAHA_API_URL=${var.waha_api_url}
WAHA_CHATWOOT_WEBHOOK_PATH=${var.waha_chatwoot_webhook_path}
WAHA_PUBLIC_URL=${var.waha_public_url}
WHATSAPP_API_CAMPAIGNS_ENABLED=${tostring(var.whatsapp_api_campaigns_enabled)}
ENV
}

resource "aws_ssm_parameter" "chatwoot_ec2_env" {
  name        = local.ec2_env_path
  description = "Chatwoot EC2 environment file"
  type        = "SecureString"
  value       = local.ec2_chatwoot_env
}

resource "aws_ssm_parameter" "chatwoot_ec2_runtime_image" {
  name        = local.ec2_runtime_path
  description = "Chatwoot EC2 Docker image URI"
  type        = "String"
  value       = local.ec2_image_uri

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_security_group" "ec2_alb" {
  name        = "${local.name}-ec2-alb"
  description = "Public access for Chatwoot EC2 ALB"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2_app" {
  name        = "${local.name}-ec2-app"
  description = "Chatwoot EC2 application access"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "ec2_app" {
  name = "${local.name}-ec2-app"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_ecr" {
  role       = aws_iam_role.ec2_app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "ec2_app" {
  name = "${local.name}-ec2-app"
  role = aws_iam_role.ec2_app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = [
          aws_ssm_parameter.chatwoot_ec2_env.arn,
          aws_ssm_parameter.chatwoot_ec2_runtime_image.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.uploads.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.uploads.arn}/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_app" {
  name = "${local.name}-ec2-app"
  role = aws_iam_role.ec2_app.name
}

resource "aws_instance" "chatwoot" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.ec2_app.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_app.name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data_replace_on_change = true
  user_data = templatefile("${path.module}/templates/chatwoot-ec2-user-data.sh.tftpl", {
    aws_region        = var.aws_region
    ecr_registry      = local.ecr_registry
    env_parameter     = aws_ssm_parameter.chatwoot_ec2_env.name
    runtime_parameter = aws_ssm_parameter.chatwoot_ec2_runtime_image.name
  })

  tags = {
    Name = "${local.name}-ec2"
  }
}

resource "aws_lb" "ec2" {
  name               = "${local.name}-ec2"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_alb.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "ec2_web" {
  name        = "${local.name}-ec2-web"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.this.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}

resource "aws_lb_target_group_attachment" "ec2_web" {
  target_group_arn = aws_lb_target_group.ec2_web.arn
  target_id        = aws_instance.chatwoot.id
  port             = 3000
}

resource "aws_lb_listener" "ec2_http" {
  load_balancer_arn = aws_lb.ec2.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "ec2_https" {
  load_balancer_arn = aws_lb.ec2.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_web.arn
  }
}
