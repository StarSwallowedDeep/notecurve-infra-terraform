terraform {
  # 1단계 apply 후, 2단계에서 주석 풀기
  # backend "s3" {
  #   bucket         = "notecurve-infra-tfstate-an2"
  #   key            = "terraform/state/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   dynamodb_table = "terraform-lock-table"
  #   encrypt        = true
  # }

  # required_providers {
  #   aws = {
  #     source  = "hashicorp/aws"
  #     version = "~> 5.0"
  #   }
  # }
}

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

  user_data = <<-EOF
                #!/bin/bash
                # 1. 패키지 업데이트
                sudo apt-get update -y
                sudo apt-get install -y ca-certificates curl gnupg

                # 2. 도커(Docker) 설치
                sudo install -m 0755 -d /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                sudo chmod a+r /etc/apt/keyrings/docker.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt-get update -y
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                sudo usermod -a -G docker ubuntu
                sudo systemctl enable docker
                sudo systemctl start docker

                # 3. 스왑 메모리 설정 (2GB) - DB 실행 시 메모리 부족 방지
                sudo fallocate -l 2G /swapfile
                sudo chmod 600 /swapfile
                sudo mkswap /swapfile
                sudo swapon /swapfile
                sudo sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'

                # 4. MySQL 서버 설치 및 실행
                sudo apt-get install -y mysql-server
                sudo systemctl start mysql
                sudo systemctl enable mysql
                EOF
}
terraform {
  # 1단계 apply 후, 2단계에서 주석 풀기
  # backend "s3" {
  #   bucket         = "notecurve-infra-tfstate-an2"
  #   key            = "terraform/state/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   dynamodb_table = "terraform-lock-table"
  #   encrypt        = true
  # }

  # required_providers {
  #   aws = {
  #     source  = "hashicorp/aws"
  #     version = "~> 5.0"
  #   }
  # }
}

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

  user_data = <<-EOF
                #!/bin/bash
                # 1. 패키지 업데이트
                sudo apt-get update -y
                sudo apt-get install -y ca-certificates curl gnupg

                # 2. 도커(Docker) 설치
                sudo install -m 0755 -d /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                sudo chmod a+r /etc/apt/keyrings/docker.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                sudo apt-get update -y
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
                sudo usermod -a -G docker ubuntu
                sudo systemctl enable docker
                sudo systemctl start docker

                # 3. 스왑 메모리 설정 (2GB) - DB 실행 시 메모리 부족 방지
                sudo fallocate -l 2G /swapfile
                sudo chmod 600 /swapfile
                sudo mkswap /swapfile
                sudo swapon /swapfile
                sudo sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'

                # 4. MySQL 서버 설치 및 실행
                sudo apt-get install -y mysql-server
                sudo systemctl start mysql
                sudo systemctl enable mysql
                EOF
}
