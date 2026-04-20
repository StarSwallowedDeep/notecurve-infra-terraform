terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # 인프라 먼저 apply 후 주석 해제
  # backend "s3" {
  #   bucket         = "<your-tfstate-bucket-name>"
  #   key            = "terraform/state/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   dynamodb_table = "terraform-lock-table"
  #   encrypt        = true
  # }
}

# -----------------------------------------------
# Provider
# -----------------------------------------------
provider "aws" {
  alias  = "seoul"
  region = "ap-northeast-2"
}

provider "aws" {
  alias  = "tokyo"
  region = "ap-northeast-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# -----------------------------------------------
# VPC - 서울
# -----------------------------------------------
module "vpc_seoul" {
  source = "./modules/vpc"

  providers = {
    aws = aws.seoul
  }

  region      = "ap-northeast-2"
  stage       = var.stage
  servicename = var.servicename
  tags        = var.tags

  vpc_cidr          = "10.1.0.0/16"
  public_subnet_az1 = "10.1.1.0/24"
  public_subnet_az2 = "10.1.2.0/24"
  private_app_az1   = "10.1.11.0/24"
  private_app_az2   = "10.1.12.0/24"
  private_db_az1    = "10.1.21.0/24"
  private_db_az2    = "10.1.22.0/24"
  az1               = "ap-northeast-2a"
  az2               = "ap-northeast-2c"
}

# -----------------------------------------------
# VPC - 도쿄
# -----------------------------------------------
module "vpc_tokyo" {
  source = "./modules/vpc"

  providers = {
    aws = aws.tokyo
  }

  region      = "ap-northeast-1"
  stage       = var.stage
  servicename = var.servicename
  tags        = var.tags

  vpc_cidr          = "10.2.0.0/16"
  public_subnet_az1 = "10.2.1.0/24"
  public_subnet_az2 = "10.2.2.0/24"
  private_app_az1   = "10.2.11.0/24"
  private_app_az2   = "10.2.12.0/24"
  private_db_az1    = "10.2.21.0/24"
  private_db_az2    = "10.2.22.0/24"
  az1               = "ap-northeast-1a"
  az2               = "ap-northeast-1c"
}

# -----------------------------------------------
# EC2 - 서울 VPN
# -----------------------------------------------
module "ec2_vpn_seoul" {
  source = "./modules/ec2"

  providers = {
    aws = aws.seoul
  }

  stage       = var.stage
  servicename = "${var.servicename}-vpn"
  tags        = var.tags

  ami           = var.vpn_ami_seoul
  instance_type = var.vpn_instance_type
  subnet_id     = module.vpc_seoul.public_subnet_az1_id
  key_name      = var.key_name_seoul

  associate_public_ip_address = true
  is_port_forwarding          = true

  vpc_id       = module.vpc_seoul.vpc_id
  extra_sg_ids = []

  ingress_rules = [
    { from_port = 22,   to_port = 22,   protocol = "tcp", cidr = "0.0.0.0/0", description = "SSH" },
    { from_port = 943,  to_port = 943,  protocol = "tcp", cidr = "0.0.0.0/0", description = "OpenVPN Admin" },
    { from_port = 443,  to_port = 443,  protocol = "tcp", cidr = "0.0.0.0/0", description = "OpenVPN HTTPS" },
    { from_port = 1194, to_port = 1194, protocol = "udp", cidr = "0.0.0.0/0", description = "OpenVPN UDP" },
  ]
}

# -----------------------------------------------
# EC2 - 도쿄 VPN
# -----------------------------------------------
module "ec2_vpn_tokyo" {
  source = "./modules/ec2"

  providers = {
    aws = aws.tokyo
  }

  stage       = var.stage
  servicename = "${var.servicename}-vpn"
  tags        = var.tags

  ami           = var.vpn_ami_tokyo
  instance_type = var.vpn_instance_type
  subnet_id     = module.vpc_tokyo.public_subnet_az1_id
  key_name      = var.key_name_tokyo

  associate_public_ip_address = true
  is_port_forwarding          = true

  vpc_id       = module.vpc_tokyo.vpc_id
  extra_sg_ids = []

  ingress_rules = [
    { from_port = 22,   to_port = 22,   protocol = "tcp", cidr = "0.0.0.0/0", description = "SSH" },
    { from_port = 943,  to_port = 943,  protocol = "tcp", cidr = "0.0.0.0/0", description = "OpenVPN Admin" },
    { from_port = 443,  to_port = 443,  protocol = "tcp", cidr = "0.0.0.0/0", description = "OpenVPN HTTPS" },
    { from_port = 1194, to_port = 1194, protocol = "udp", cidr = "0.0.0.0/0", description = "OpenVPN UDP" },
  ]
}

# -----------------------------------------------
# EC2 - 서울 앱 AZ1
# -----------------------------------------------
module "ec2_app_seoul_az1" {
  source = "./modules/ec2"

  providers = {
    aws = aws.seoul
  }

  stage       = var.stage
  servicename = "${var.servicename}-app-az1"
  tags        = var.tags

  ami           = var.app_ami_seoul
  instance_type = var.app_instance_type
  subnet_id     = module.vpc_seoul.private_app_az1_id
  key_name      = var.key_name_seoul
  user_data     = file("${path.module}/scripts/app_userdata.sh")

  associate_public_ip_address = false
  is_port_forwarding          = false

  vpc_id       = module.vpc_seoul.vpc_id
  extra_sg_ids = []

  ingress_rules = [
    { from_port = 22,   to_port = 22,   protocol = "tcp", cidr = module.vpc_seoul.vpc_cidr, description = "SSH from VPC" },
    { from_port = 8080, to_port = 8080, protocol = "tcp", cidr = module.vpc_seoul.vpc_cidr, description = "App port" },
    { from_port = 8081, to_port = 8081, protocol = "tcp", cidr = module.vpc_seoul.vpc_cidr, description = "Admin port" },
  ]
}

# -----------------------------------------------
# EC2 - 서울 앱 AZ2
# -----------------------------------------------
module "ec2_app_seoul_az2" {
  source = "./modules/ec2"

  providers = {
    aws = aws.seoul
  }

  stage       = var.stage
  servicename = "${var.servicename}-app-az2"
  tags        = var.tags

  ami           = var.app_ami_seoul
  instance_type = var.app_instance_type
  subnet_id     = module.vpc_seoul.private_app_az2_id
  key_name      = var.key_name_seoul
  user_data     = file("${path.module}/scripts/app_userdata.sh")

  associate_public_ip_address = false
  is_port_forwarding          = false

  vpc_id       = module.vpc_seoul.vpc_id
  extra_sg_ids = []

  ingress_rules = [
    { from_port = 22,   to_port = 22,   protocol = "tcp", cidr = module.vpc_seoul.vpc_cidr, description = "SSH from VPC" },
    { from_port = 8080, to_port = 8080, protocol = "tcp", cidr = module.vpc_seoul.vpc_cidr, description = "App port" },
    { from_port = 8081, to_port = 8081, protocol = "tcp", cidr = module.vpc_seoul.vpc_cidr, description = "Admin port" },
  ]
}

# -----------------------------------------------
# EC2 - 도쿄 앱 AZ1 (Warm Standby)
# -----------------------------------------------
module "ec2_app_tokyo_az1" {
  source = "./modules/ec2"

  providers = {
    aws = aws.tokyo
  }

  stage       = var.stage
  servicename = "${var.servicename}-app-az1"
  tags        = var.tags

  ami           = var.app_ami_tokyo
  instance_type = var.app_instance_type
  subnet_id     = module.vpc_tokyo.private_app_az1_id
  key_name      = var.key_name_tokyo
  user_data     = file("${path.module}/scripts/app_userdata.sh")

  associate_public_ip_address = false
  is_port_forwarding          = false

  vpc_id       = module.vpc_tokyo.vpc_id
  extra_sg_ids = []

  ingress_rules = [
    { from_port = 22,   to_port = 22,   protocol = "tcp", cidr = module.vpc_tokyo.vpc_cidr, description = "SSH from VPC" },
    { from_port = 8080, to_port = 8080, protocol = "tcp", cidr = module.vpc_tokyo.vpc_cidr, description = "App port" },
    { from_port = 8081, to_port = 8081, protocol = "tcp", cidr = module.vpc_tokyo.vpc_cidr, description = "Admin port" },
  ]
}

# -----------------------------------------------
# EC2 - 도쿄 앱 AZ2 (Warm Standby)
# -----------------------------------------------
module "ec2_app_tokyo_az2" {
  source = "./modules/ec2"

  providers = {
    aws = aws.tokyo
  }

  stage       = var.stage
  servicename = "${var.servicename}-app-az2"
  tags        = var.tags

  ami           = var.app_ami_tokyo
  instance_type = var.app_instance_type
  subnet_id     = module.vpc_tokyo.private_app_az2_id
  key_name      = var.key_name_tokyo
  user_data     = file("${path.module}/scripts/app_userdata.sh")

  associate_public_ip_address = false
  is_port_forwarding          = false

  vpc_id       = module.vpc_tokyo.vpc_id
  extra_sg_ids = []

  ingress_rules = [
    { from_port = 22,   to_port = 22,   protocol = "tcp", cidr = module.vpc_tokyo.vpc_cidr, description = "SSH from VPC" },
    { from_port = 8080, to_port = 8080, protocol = "tcp", cidr = module.vpc_tokyo.vpc_cidr, description = "App port" },
    { from_port = 8081, to_port = 8081, protocol = "tcp", cidr = module.vpc_tokyo.vpc_cidr, description = "Admin port" },
  ]
}

# -----------------------------------------------
# EC2 - 서울 Redis + Kafka (Master)
# -----------------------------------------------
module "ec2_rk_seoul" {
  source = "./modules/ec2"

  providers = {
    aws = aws.seoul
  }

  stage       = var.stage
  servicename = "${var.servicename}-rk"
  tags        = var.tags

  ami           = var.app_ami_seoul
  instance_type = var.rk_instance_type
  subnet_id     = module.vpc_seoul.private_db_az1_id
  key_name      = var.key_name_seoul
  user_data     = file("${path.module}/scripts/rk_seoul_userdata.sh")

  associate_public_ip_address = false
  is_port_forwarding          = false

  vpc_id       = module.vpc_seoul.vpc_id
  extra_sg_ids = []

  ingress_rules = [
    { from_port = 22,   to_port = 22,   protocol = "tcp", cidr = module.vpc_seoul.vpc_cidr,      description = "SSH from VPC" },
    { from_port = 6379, to_port = 6379, protocol = "tcp", cidr = module.vpc_seoul.vpc_cidr,      description = "Redis from Seoul" },
    { from_port = 9092, to_port = 9092, protocol = "tcp", cidr = module.vpc_seoul.vpc_cidr,      description = "Kafka from Seoul" },
    { from_port = 9093, to_port = 9093, protocol = "tcp", cidr = module.vpc_seoul.vpc_cidr,      description = "Kafka Controller" },
    { from_port = 6379, to_port = 6379, protocol = "tcp", cidr = module.vpc_tokyo.vpc_cidr,      description = "Redis from Tokyo" },
    { from_port = 9092, to_port = 9092, protocol = "tcp", cidr = module.vpc_tokyo.vpc_cidr,      description = "Kafka from Tokyo" },
  ]
}

# -----------------------------------------------
# EC2 - 도쿄 Redis + Kafka (Replica)
# -----------------------------------------------
module "ec2_rk_tokyo" {
  source = "./modules/ec2"

  providers = {
    aws = aws.tokyo
  }

  stage       = var.stage
  servicename = "${var.servicename}-rk"
  tags        = var.tags

  ami           = var.app_ami_tokyo
  instance_type = var.rk_instance_type
  subnet_id     = module.vpc_tokyo.private_db_az1_id
  key_name      = var.key_name_tokyo
  user_data     = templatefile("${path.module}/scripts/rk_tokyo_userdata.sh.tpl", {
    seoul_rk_ip = module.ec2_rk_seoul.private_ip
  })

  associate_public_ip_address = false
  is_port_forwarding          = false

  vpc_id       = module.vpc_tokyo.vpc_id
  extra_sg_ids = []

  ingress_rules = [
    { from_port = 22,   to_port = 22,   protocol = "tcp", cidr = module.vpc_tokyo.vpc_cidr, description = "SSH from VPC" },
    { from_port = 6379, to_port = 6379, protocol = "tcp", cidr = module.vpc_tokyo.vpc_cidr, description = "Redis" },
    { from_port = 9092, to_port = 9092, protocol = "tcp", cidr = module.vpc_tokyo.vpc_cidr, description = "Kafka" },
    { from_port = 9093, to_port = 9093, protocol = "tcp", cidr = module.vpc_tokyo.vpc_cidr, description = "Kafka Controller" },
  ]
}

# -----------------------------------------------
# ALB - 서울
# -----------------------------------------------
module "alb_seoul" {
  source = "./modules/alb"

  providers = {
    aws = aws.seoul
  }

  stage       = var.stage
  servicename = var.servicename
  tags        = var.tags

  vpc_id         = module.vpc_seoul.vpc_id
  public_subnets = [module.vpc_seoul.public_subnet_az1_id, module.vpc_seoul.public_subnet_az2_id]
  target_instance_ids = [
    module.ec2_app_seoul_az1.instance_id,
    module.ec2_app_seoul_az2.instance_id,
  ]
  app_port            = 8080
  vpc_cidr            = module.vpc_seoul.vpc_cidr
  acm_certificate_arn = var.acm_arn_seoul
  domain_name         = var.domain_name
}

# -----------------------------------------------
# ALB - 도쿄
# -----------------------------------------------
module "alb_tokyo" {
  source = "./modules/alb"

  providers = {
    aws = aws.tokyo
  }

  stage       = var.stage
  servicename = var.servicename
  tags        = var.tags

  vpc_id         = module.vpc_tokyo.vpc_id
  public_subnets = [module.vpc_tokyo.public_subnet_az1_id, module.vpc_tokyo.public_subnet_az2_id]
  target_instance_ids = [
    module.ec2_app_tokyo_az1.instance_id,
    module.ec2_app_tokyo_az2.instance_id,
  ]
  app_port            = 8080
  vpc_cidr            = module.vpc_tokyo.vpc_cidr
  acm_certificate_arn = var.acm_arn_tokyo
  domain_name         = var.domain_name
}

# -----------------------------------------------
# S3 + CloudFront
# -----------------------------------------------
module "s3_cf" {
  source = "./modules/s3_cf"

  providers = {
    aws           = aws.seoul
    aws.us_east_1 = aws.us_east_1
    aws.tokyo     = aws.tokyo
  }

  stage       = var.stage
  servicename = var.servicename
  tags        = var.tags
}

# -----------------------------------------------
# VPC Peering - 서울 ↔ 도쿄
# -----------------------------------------------
module "vpc_peering" {
  source = "./modules/vpc_peering"

  providers = {
    aws.requester = aws.seoul
    aws.accepter  = aws.tokyo
  }

  tags = var.tags

  requester_vpc_id            = module.vpc_seoul.vpc_id
  requester_vpc_cidr          = module.vpc_seoul.vpc_cidr
  requester_private_rt_az1_id = module.vpc_seoul.private_rt_az1_id
  requester_private_rt_az2_id = module.vpc_seoul.private_rt_az2_id

  accepter_vpc_id            = module.vpc_tokyo.vpc_id
  accepter_vpc_cidr          = module.vpc_tokyo.vpc_cidr
  accepter_region            = "ap-northeast-1"
  accepter_private_rt_az1_id = module.vpc_tokyo.private_rt_az1_id
  accepter_private_rt_az2_id = module.vpc_tokyo.private_rt_az2_id
}

# -----------------------------------------------
# RDS Aurora Global Database (MySQL)
# -----------------------------------------------
module "rds" {
  source = "./modules/rds"

  providers = {
    aws.primary   = aws.seoul
    aws.secondary = aws.tokyo
  }

  stage       = var.stage
  servicename = var.servicename
  tags        = var.tags

  database_name   = var.database_name
  master_username = var.db_username
  master_password = var.db_password
  instance_class  = var.db_instance_class

  primary_vpc_id        = module.vpc_seoul.vpc_id
  primary_vpc_cidr      = module.vpc_seoul.vpc_cidr
  primary_db_subnet_ids = [
    module.vpc_seoul.private_db_az1_id,
    module.vpc_seoul.private_db_az2_id,
  ]

  secondary_vpc_id        = module.vpc_tokyo.vpc_id
  secondary_vpc_cidr      = module.vpc_tokyo.vpc_cidr
  secondary_db_subnet_ids = [
    module.vpc_tokyo.private_db_az1_id,
    module.vpc_tokyo.private_db_az2_id,
  ]
}

# -----------------------------------------------
# Route 53 헬스체크 + 장애조치 레코드
# -----------------------------------------------
module "route53" {
  source = "./modules/route53"

  tags           = var.tags
  domain_name    = var.domain_name
  hosted_zone_id = var.hosted_zone_id

  seoul_alb_dns     = module.alb_seoul.alb_dns_name
  seoul_alb_zone_id = module.alb_seoul.alb_zone_id
  tokyo_alb_dns     = module.alb_tokyo.alb_dns_name
  tokyo_alb_zone_id = module.alb_tokyo.alb_zone_id
}

# -----------------------------------------------
# Lambda DR 자동화
# -----------------------------------------------
module "lambda" {
  source = "./modules/lambda"

  providers = {
    aws = aws.seoul
  }

  stage       = var.stage
  servicename = var.servicename
  tags        = var.tags

  alert_email          = var.alert_email
  global_cluster_id    = module.rds.global_cluster_id
  secondary_cluster_id = var.secondary_cluster_id
  tokyo_rk_ec2_id      = module.ec2_rk_tokyo.instance_id
  tokyo_app_ec2_ids    = [
    module.ec2_app_tokyo_az1.instance_id,
    module.ec2_app_tokyo_az2.instance_id,
  ]
  tokyo_vpn_ec2_id      = module.ec2_vpn_tokyo.instance_id
  seoul_alb_arn_suffix  = module.alb_seoul.alb_arn_suffix
  seoul_health_check_id = module.route53.seoul_health_check_id
}
