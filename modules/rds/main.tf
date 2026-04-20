terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [aws.primary, aws.secondary]
    }
  }
}

locals {
  prefix = "aws-${var.stage}-${var.servicename}"
}

# -----------------------------------------------
# KMS 키 - 도쿄 (Secondary 암호화용)
# -----------------------------------------------
resource "aws_kms_key" "secondary" {
  provider                = aws.secondary
  description             = "${local.prefix} Aurora secondary encryption key"
  deletion_window_in_days = 7

  tags = merge(var.tags, { Name = "${local.prefix}-aurora-kms" })
}

# -----------------------------------------------
# DB 서브넷 그룹 - 서울 (Primary)
# -----------------------------------------------
resource "aws_db_subnet_group" "primary" {
  provider   = aws.primary
  name       = "${local.prefix}-subnet-group"
  subnet_ids = var.primary_db_subnet_ids

  tags = merge(var.tags, { Name = "${local.prefix}-subnet-group" })
}

# -----------------------------------------------
# DB 서브넷 그룹 - 도쿄 (Secondary)
# -----------------------------------------------
resource "aws_db_subnet_group" "secondary" {
  provider   = aws.secondary
  name       = "${local.prefix}-subnet-group"
  subnet_ids = var.secondary_db_subnet_ids

  tags = merge(var.tags, { Name = "${local.prefix}-subnet-group" })
}

# -----------------------------------------------
# 보안 그룹 - 서울
# -----------------------------------------------
resource "aws_security_group" "primary" {
  provider = aws.primary
  name     = "${local.prefix}-aurora-sg"
  vpc_id   = var.primary_vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.primary_vpc_cidr]
    description = "MySQL from Seoul VPC"
  }

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.secondary_vpc_cidr]
    description = "MySQL from Tokyo VPC (replication)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.prefix}-aurora-sg" })
}

# -----------------------------------------------
# 보안 그룹 - 도쿄
# -----------------------------------------------
resource "aws_security_group" "secondary" {
  provider = aws.secondary
  name     = "${local.prefix}-aurora-sg"
  vpc_id   = var.secondary_vpc_id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.secondary_vpc_cidr]
    description = "MySQL from Tokyo VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.prefix}-aurora-sg" })
}

# -----------------------------------------------
# Aurora Global Database
# -----------------------------------------------
resource "aws_rds_global_cluster" "this" {
  provider                  = aws.primary
  global_cluster_identifier = "${local.prefix}-global"
  engine                    = "aurora-mysql"
  engine_version            = "8.0.mysql_aurora.3.04.1"
  database_name             = var.database_name
  storage_encrypted         = true

  lifecycle {
    ignore_changes = [engine_version]
  }
}

# -----------------------------------------------
# Aurora 클러스터 - 서울 (Primary)
# -----------------------------------------------
resource "aws_rds_cluster" "primary" {
  provider                  = aws.primary
  cluster_identifier        = "${local.prefix}-primary"
  engine                    = "aurora-mysql"
  engine_version            = "8.0.mysql_aurora.3.04.1"
  global_cluster_identifier = aws_rds_global_cluster.this.id
  db_subnet_group_name      = aws_db_subnet_group.primary.name
  vpc_security_group_ids    = [aws_security_group.primary.id]

  master_username         = var.master_username
  master_password         = var.master_password
  backup_retention_period = 7
  preferred_backup_window = "02:00-03:00"
  skip_final_snapshot     = true
  storage_encrypted       = true

  tags = merge(var.tags, { Name = "${local.prefix}-primary" })

  lifecycle {
    ignore_changes = [global_cluster_identifier, engine_version]
  }
}

# -----------------------------------------------
# Aurora 인스턴스 - 서울 (Writer)
# -----------------------------------------------
resource "aws_rds_cluster_instance" "primary" {
  provider             = aws.primary
  identifier           = "${local.prefix}-primary-instance"
  cluster_identifier   = aws_rds_cluster.primary.id
  instance_class       = var.instance_class
  engine               = "aurora-mysql"
  engine_version       = "8.0.mysql_aurora.3.04.1"
  db_subnet_group_name = aws_db_subnet_group.primary.name

  tags = merge(var.tags, { Name = "${local.prefix}-primary-instance" })

  lifecycle {
    ignore_changes = [engine_version]
  }
}

# -----------------------------------------------
# Aurora 클러스터 - 도쿄 (Secondary)
# KMS 키 명시로 크로스 리전 암호화 에러 해결
# -----------------------------------------------
resource "aws_rds_cluster" "secondary" {
  provider                  = aws.secondary
  cluster_identifier        = "${local.prefix}-secondary"
  engine                    = "aurora-mysql"
  engine_version            = "8.0.mysql_aurora.3.04.1"
  global_cluster_identifier = aws_rds_global_cluster.this.id
  db_subnet_group_name      = aws_db_subnet_group.secondary.name
  vpc_security_group_ids    = [aws_security_group.secondary.id]
  kms_key_id                = aws_kms_key.secondary.arn
  storage_encrypted         = true
  skip_final_snapshot       = true

  tags = merge(var.tags, { Name = "${local.prefix}-secondary" })

  lifecycle {
    ignore_changes = [
      global_cluster_identifier,
      engine_version,
      master_username,
      master_password,
    ]
  }

  depends_on = [aws_rds_cluster_instance.primary]
}

# -----------------------------------------------
# Aurora 인스턴스 - 도쿄 (Reader)
# -----------------------------------------------
resource "aws_rds_cluster_instance" "secondary" {
  provider             = aws.secondary
  identifier           = "${local.prefix}-secondary-instance"
  cluster_identifier   = aws_rds_cluster.secondary.id
  instance_class       = var.instance_class
  engine               = "aurora-mysql"
  engine_version       = "8.0.mysql_aurora.3.04.1"
  db_subnet_group_name = aws_db_subnet_group.secondary.name

  tags = merge(var.tags, { Name = "${local.prefix}-secondary-instance" })

  lifecycle {
    ignore_changes = [engine_version]
  }
}
