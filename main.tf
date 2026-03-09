provider "aws" {
  region = "ap-northeast-2"
}

# VPC 모듈
module "vpc" {
  source = "./vpc"
}

# EC2 모듈
module "ec2" {
  source    = "./ec2"
  subnet_id = module.vpc.public-az1.id
}
