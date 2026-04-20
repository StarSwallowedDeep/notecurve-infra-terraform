terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [aws.requester, aws.accepter]
    }
  }
}

# -----------------------------------------------
# VPC Peering 요청 (서울에서 도쿄로 요청)
# -----------------------------------------------
resource "aws_vpc_peering_connection" "this" {
  provider    = aws.requester

  vpc_id      = var.requester_vpc_id      # 서울 VPC
  peer_vpc_id = var.accepter_vpc_id       # 도쿄 VPC
  peer_region = var.accepter_region       # ap-northeast-1

  auto_accept = false

  tags = merge(var.tags, {
    Name = "vpc-peering-seoul-tokyo"
    Side = "Requester"
  })
}

# -----------------------------------------------
# VPC Peering 수락 (도쿄에서 수락)
# -----------------------------------------------
resource "aws_vpc_peering_connection_accepter" "this" {
  provider                  = aws.accepter
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  auto_accept               = true

  tags = merge(var.tags, {
    Name = "vpc-peering-seoul-tokyo"
    Side = "Accepter"
  })
}

# -----------------------------------------------
# 서울 라우팅 테이블에 도쿄 CIDR 추가
# (프라이빗 AZ1, AZ2 → 도쿄로 가는 경로)
# -----------------------------------------------
resource "aws_route" "seoul_to_tokyo_az1" {
  provider                  = aws.requester
  route_table_id            = var.requester_private_rt_az1_id
  destination_cidr_block    = var.accepter_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_route" "seoul_to_tokyo_az2" {
  provider                  = aws.requester
  route_table_id            = var.requester_private_rt_az2_id
  destination_cidr_block    = var.accepter_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

# -----------------------------------------------
# 도쿄 라우팅 테이블에 서울 CIDR 추가
# (프라이빗 AZ1, AZ2 → 서울로 가는 경로)
# -----------------------------------------------
resource "aws_route" "tokyo_to_seoul_az1" {
  provider                  = aws.accepter
  route_table_id            = var.accepter_private_rt_az1_id
  destination_cidr_block    = var.requester_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}

resource "aws_route" "tokyo_to_seoul_az2" {
  provider                  = aws.accepter
  route_table_id            = var.accepter_private_rt_az2_id
  destination_cidr_block    = var.requester_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.this.id
}
