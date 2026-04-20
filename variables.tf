# -----------------------------------------------
# 공통 태그 / 네이밍
# -----------------------------------------------
variable "stage" {
  type        = string
  default     = "dev"
  description = "배포 환경 (dev / stg / prod)"
}

variable "servicename" {
  type        = string
  default     = "myapp"
  description = "서비스 이름"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "dev"
    Owner       = "myteam"
    ManagedBy   = "terraform"
  }
}

# -----------------------------------------------
# EC2 키페어
# -----------------------------------------------
variable "key_name_seoul" {
  type        = string
  description = "서울 EC2 키페어 이름"
}

variable "key_name_tokyo" {
  type        = string
  description = "도쿄 EC2 키페어 이름"
}

# -----------------------------------------------
# EC2 앱 서버
# -----------------------------------------------
variable "app_instance_type" {
  type        = string
  default     = "t3.small"
  description = "앱 서버 인스턴스 타입"
}

variable "app_ami_seoul" {
  type        = string
  description = "서울 리전 앱 서버 AMI ID"
}

variable "app_ami_tokyo" {
  type        = string
  description = "도쿄 리전 앱 서버 AMI ID"
}

# -----------------------------------------------
# EC2 VPN 서버  ← 신규 추가
# -----------------------------------------------
variable "vpn_ami_seoul" {
  type        = string
  description = "서울 리전 VPN 서버 AMI ID"
}

variable "vpn_ami_tokyo" {
  type        = string
  description = "도쿄 리전 VPN 서버 AMI ID"
}

variable "vpn_instance_type" {
  type        = string
  default     = "t3.small"
  description = "VPN 서버 인스턴스 타입"
}

# -----------------------------------------------
# EC2 Redis + Kafka 서버  ← 신규 추가
# -----------------------------------------------
variable "rk_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "Redis + Kafka 서버 인스턴스 타입"
}

# -----------------------------------------------
# RDS Aurora
# -----------------------------------------------
variable "database_name" {
  type        = string
  description = "Aurora MySQL 데이터베이스 이름"  # ← 신규 추가
}

variable "db_username" {
  type        = string
  description = "Aurora MySQL 마스터 계정"
  default     = "admin"
}

variable "db_password" {
  type        = string
  description = "Aurora MySQL 마스터 비밀번호"
  sensitive   = true
}

variable "db_instance_class" {
  type        = string
  default     = "db.r6g.large"
  description = "Aurora 인스턴스 타입"
}

# -----------------------------------------------
# Route 53 / 도메인
# -----------------------------------------------
variable "domain_name" {
  type        = string
  description = "서비스 도메인 이름"
}

variable "hosted_zone_id" {
  type        = string
  description = "Route 53 호스팅 영역 ID"
}

# -----------------------------------------------
# ACM 인증서 ARN
# -----------------------------------------------
variable "acm_arn_seoul" {
  type        = string
  description = "서울 ACM 인증서 ARN"
}

variable "acm_arn_tokyo" {
  type        = string
  description = "도쿄 ACM 인증서 ARN"
}

# -----------------------------------------------
# Lambda / 알림
# -----------------------------------------------
variable "alert_email" {
  type        = string
  description = "장애 알림 받을 이메일"
}

variable "secondary_cluster_id" {
  type        = string
  description = "DR용 Aurora 보조 클러스터 ID"  # ← 신규 추가
}
