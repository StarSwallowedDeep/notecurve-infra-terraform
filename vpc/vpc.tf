# VPC 생성
resource "aws_vpc" "aws-vpc" {
  cidr_block           = var.vpc_ip_range
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(tomap({
    Name = "aws-vpc-${var.stage}-${var.servicename}"}),
    var.tags)
}

# 퍼블릭 서브넷 생성 (az1)
resource "aws_subnet" "public-az1" {
  vpc_id                  = aws_vpc.aws-vpc.id
  cidr_block              = var.subnet_public_az1
  map_public_ip_on_launch = false
  availability_zone       = var.az
  tags = merge(tomap({
    Name = "aws-subnet-${var.stage}-${var.servicename}-pub-az1"}),
    var.tags)
  depends_on = [aws_vpc.aws-vpc]
}

# 인터넷 게이트웨이 생성
resource "aws_internet_gateway" "vpc-igw" {
  vpc_id = aws_vpc.aws-vpc.id
  tags = merge(tomap({
    Name = "aws-igw-${var.stage}-${var.servicename}"}),
    var.tags)
}

# 퍼블릭 라우팅 테이블 생성
resource "aws_route_table" "aws-rt-pub" {
  vpc_id = aws_vpc.aws-vpc.id
  tags = merge(tomap({
    Name = "aws-rt-${var.stage}-${var.servicename}-pub"}),
    var.tags)
}

# IGW로 향하는 라우팅 규칙 (인터넷 연결)
resource "aws_route" "route-to-igw" {
  route_table_id         = aws_route_table.aws-rt-pub.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc-igw.id
  lifecycle {
    create_before_destroy = true
  }
}

# 퍼블릭 서브넷과 라우팅 테이블 연결
resource "aws_route_table_association" "public-az1" {
  subnet_id      = aws_subnet.public-az1.id
  route_table_id = aws_route_table.aws-rt-pub.id
}
