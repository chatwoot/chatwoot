data "aws_caller_identity" "current" {}

locals {
  name                        = "${var.project}-${var.environment}"
  ecr_image_url               = "${aws_ecr_repository.chatwoot.repository_url}:${var.image_tag}"
  vpc_id                      = var.existing_vpc_id
  public_subnet_ids           = var.existing_public_subnet_ids
  database_subnet_ids         = var.existing_database_subnet_ids
  ec2_subnet_id               = var.existing_ec2_subnet_id != "" ? var.existing_ec2_subnet_id : var.existing_public_subnet_ids[0]
  github_actions_repositories = distinct(concat([var.github_actions_repository], var.github_actions_extra_repositories))
  github_actions_subjects = flatten([
    for repository in local.github_actions_repositories : [
      "repo:${repository}:ref:refs/heads/${var.github_branch}",
      "repo:${repository}:pull_request",
      "repo:${repository}:environment:production"
    ]
  ])

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = "chatwoot"
  }
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

resource "random_password" "db" {
  length  = 24
  special = false
}

resource "random_password" "secret_key_base" {
  length  = 96
  special = false
}

resource "random_password" "redis" {
  length  = 32
  special = false
}

resource "aws_security_group" "rds" {
  name        = "${local.name}-rds"
  description = "PostgreSQL access from Chatwoot EC2"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "redis" {
  name        = "${local.name}-redis"
  description = "Redis access from Chatwoot EC2"
  vpc_id      = local.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "chatwoot" {
  name       = local.name
  subnet_ids = local.database_subnet_ids
}

resource "aws_db_instance" "chatwoot" {
  identifier              = local.name
  engine                  = "postgres"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp3"
  db_name                 = "chatwoot_production"
  username                = "chatwoot"
  password                = random_password.db.result
  db_subnet_group_name    = aws_db_subnet_group.chatwoot.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  publicly_accessible     = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = var.rds_backup_retention_period
}

resource "aws_elasticache_subnet_group" "chatwoot" {
  name       = local.name
  subnet_ids = local.database_subnet_ids
}

resource "aws_elasticache_replication_group" "chatwoot" {
  replication_group_id = "${local.name}-redis"
  description          = "Chatwoot Redis"
  engine               = "redis"
  node_type            = "cache.t4g.micro"
  num_cache_clusters   = 1
  parameter_group_name = "default.redis7"
  engine_version       = "7.1"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.chatwoot.name
  security_group_ids   = [aws_security_group.redis.id]

  transit_encryption_enabled = true
  auth_token                 = random_password.redis.result
}

resource "aws_s3_bucket" "uploads" {
  bucket = "${local.name}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_ecr_repository" "chatwoot" {
  name                 = local.name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "chatwoot" {
  repository = aws_ecr_repository.chatwoot.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_iam_role" "github_actions_deploy" {
  name = "${local.name}-github-actions-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github_actions.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = local.github_actions_subjects
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name = "${local.name}-github-actions-deploy"
  role = aws_iam_role.github_actions_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = aws_ecr_repository.chatwoot.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetCommandInvocation",
          "ssm:GetParameter",
          "ssm:ListCommandInvocations",
          "ssm:DescribeInstanceInformation",
          "ssm:SendCommand"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:PutParameter"
        ]
        Resource = [
          aws_ssm_parameter.chatwoot_ec2_env.arn,
          aws_ssm_parameter.chatwoot_ec2_runtime_image.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:PutParameter"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/chatwoot/${var.environment}/blue-green/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:RunInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = aws_iam_role.ec2_app.arn
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:CreateTargetGroup",
          "elasticloadbalancing:DeleteTargetGroup",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:ModifyListener",
          "elasticloadbalancing:RegisterTargets"
        ]
        Resource = "*"
      }
    ]
  })
}
