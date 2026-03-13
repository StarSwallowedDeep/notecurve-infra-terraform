data "aws_subnet" "subnet" {
  id = var.subnet_id
}

locals {
  vpc_id = data.aws_subnet.subnet.vpc_id
}

# EC2 인스턴스 생성
resource "aws_instance" "ec2" {
  associate_public_ip_address = var.associate_public_ip_address
  ami                         = var.ami
  instance_type               = var.instance_type
  vpc_security_group_ids      = concat(var.sg_ec2_ids, [aws_security_group.sg-ec2-comm.id])
  subnet_id                   = var.subnet_id
  source_dest_check           = !var.isPortForwarding

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    volume_size           = 20
  }

  user_data = var.user_data
  key_name = var.key_name

  # 워크스페이스 dev, staging, prod
  tags = merge(tomap({
    Name = "aws-ec2-${terraform.workspace}-${var.servicename}"}),
    var.tags)
}

# 보안그룹 생성
resource "aws_security_group" "sg-ec2-comm" {
  # 워크스페이스 dev, staging, prod
  name   = "aws-sg-${terraform.workspace}-${var.servicename}-ec2"
  vpc_id = local.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = var.ssh_allow_comm_list
    description = ""
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 워크스페이스 dev, staging, prod
  tags = merge(tomap({
    Name = "aws-sg-${terraform.workspace}-${var.servicename}-ec2"}),
    var.tags)
}
