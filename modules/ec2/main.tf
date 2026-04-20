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
# 보안 그룹
# -----------------------------------------------
resource "aws_security_group" "this" {
  name   = "${local.prefix}-sg"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = [ingress.value.cidr]
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.prefix}-sg" })
}

# -----------------------------------------------
# EC2 인스턴스
# -----------------------------------------------
resource "aws_instance" "this" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  associate_public_ip_address = var.associate_public_ip_address
  source_dest_check           = !var.is_port_forwarding

  vpc_security_group_ids = concat(
    [aws_security_group.this.id],
    var.extra_sg_ids
  )

  root_block_device {
    volume_size           = var.volume_size
    delete_on_termination = true
    encrypted             = true
  }

  user_data = var.user_data

  tags = merge(var.tags, { Name = "${local.prefix}-ec2" })

  lifecycle {
    ignore_changes = [ami, user_data] # 배포 후 AMI 변경으로 인한 재생성 방지
  }
}
