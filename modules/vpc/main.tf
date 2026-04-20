terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  prefix = "aws-${var.stage}-${var.servicename}"
}

# -----------------------------------------------
# VPC
# -----------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "${local.prefix}-vpc" })
}

# -----------------------------------------------
# 퍼블릭 서브넷 (2개)
# -----------------------------------------------
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_az1
  availability_zone       = var.az1
  map_public_ip_on_launch = false

  tags = merge(var.tags, { Name = "${local.prefix}-pub-az1" })
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_az2
  availability_zone       = var.az2
  map_public_ip_on_launch = false

  tags = merge(var.tags, { Name = "${local.prefix}-pub-az2" })
}

# -----------------------------------------------
# 프라이빗 서브넷 - 앱 (2개)
# -----------------------------------------------
resource "aws_subnet" "private_app_az1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_app_az1
  availability_zone = var.az1

  tags = merge(var.tags, { Name = "${local.prefix}-priv-app-az1" })
}

resource "aws_subnet" "private_app_az2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_app_az2
  availability_zone = var.az2

  tags = merge(var.tags, { Name = "${local.prefix}-priv-app-az2" })
}

# -----------------------------------------------
# 프라이빗 서브넷 - DB (2개)
# -----------------------------------------------
resource "aws_subnet" "private_db_az1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_db_az1
  availability_zone = var.az1

  tags = merge(var.tags, { Name = "${local.prefix}-priv-db-az1" })
}

resource "aws_subnet" "private_db_az2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_db_az2
  availability_zone = var.az2

  tags = merge(var.tags, { Name = "${local.prefix}-priv-db-az2" })
}

# -----------------------------------------------
# Internet Gateway
# -----------------------------------------------
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${local.prefix}-igw" })
}

# -----------------------------------------------
# NAT Gateway (AZ별 2개 - HA 구성)
# -----------------------------------------------
resource "aws_eip" "nat_az1" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${local.prefix}-eip-nat-az1" })
}

resource "aws_eip" "nat_az2" {
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${local.prefix}-eip-nat-az2" })
}

resource "aws_nat_gateway" "az1" {
  allocation_id = aws_eip.nat_az1.id
  subnet_id     = aws_subnet.public_az1.id

  tags = merge(var.tags, { Name = "${local.prefix}-nat-az1" })
  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "az2" {
  allocation_id = aws_eip.nat_az2.id
  subnet_id     = aws_subnet.public_az2.id

  tags = merge(var.tags, { Name = "${local.prefix}-nat-az2" })
  depends_on = [aws_internet_gateway.this]
}

# -----------------------------------------------
# 라우팅 테이블 - 퍼블릭
# -----------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, { Name = "${local.prefix}-rt-pub" })
}

resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

# -----------------------------------------------
# 라우팅 테이블 - 프라이빗 AZ1 (앱 + DB)
# -----------------------------------------------
resource "aws_route_table" "private_az1" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.az1.id
  }

  tags = merge(var.tags, { Name = "${local.prefix}-rt-priv-az1" })
}

resource "aws_route_table_association" "private_app_az1" {
  subnet_id      = aws_subnet.private_app_az1.id
  route_table_id = aws_route_table.private_az1.id
}

resource "aws_route_table_association" "private_db_az1" {
  subnet_id      = aws_subnet.private_db_az1.id
  route_table_id = aws_route_table.private_az1.id
}

# -----------------------------------------------
# 라우팅 테이블 - 프라이빗 AZ2 (앱 + DB)
# -----------------------------------------------
resource "aws_route_table" "private_az2" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.az2.id
  }

  tags = merge(var.tags, { Name = "${local.prefix}-rt-priv-az2" })
}

resource "aws_route_table_association" "private_app_az2" {
  subnet_id      = aws_subnet.private_app_az2.id
  route_table_id = aws_route_table.private_az2.id
}

resource "aws_route_table_association" "private_db_az2" {
  subnet_id      = aws_subnet.private_db_az2.id
  route_table_id = aws_route_table.private_az2.id
}
