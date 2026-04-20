# -----------------------------------------------
# 서울 VPC
# -----------------------------------------------
output "seoul_vpc_id" {
  value = module.vpc_seoul.vpc_id
}

output "seoul_alb_dns" {
  description = "서울 ALB DNS (Route 53 헬스체크에 사용)"
  value       = module.alb_seoul.alb_dns_name
}

# -----------------------------------------------
# 도쿄 VPC
# -----------------------------------------------
output "tokyo_vpc_id" {
  value = module.vpc_tokyo.vpc_id
}

output "tokyo_alb_dns" {
  description = "도쿄 ALB DNS (Route 53 장애조치 대상)"
  value       = module.alb_tokyo.alb_dns_name
}

# -----------------------------------------------
# S3 / CloudFront
# -----------------------------------------------
output "cloudfront_domain" {
  description = "CloudFront 배포 도메인"
  value       = module.s3_cf.cloudfront_domain
}

output "s3_seoul_bucket" {
  value = module.s3_cf.seoul_bucket_name
}

output "s3_tokyo_bucket" {
  value = module.s3_cf.tokyo_bucket_name
}

# -----------------------------------------------
# EC2
# -----------------------------------------------
output "vpn_public_ip" {
  description = "OpenVPN 서버 퍼블릭 IP"
  value       = module.ec2_vpn_seoul.public_ip
}

output "app_seoul_az1_ip" {
  value = module.ec2_app_seoul_az1.private_ip
}

output "app_seoul_az2_ip" {
  value = module.ec2_app_seoul_az2.private_ip
}

output "app_tokyo_az1_ip" {
  value = module.ec2_app_tokyo_az1.private_ip
}

output "app_tokyo_az2_ip" {
  value = module.ec2_app_tokyo_az2.private_ip
}

# -----------------------------------------------
# RDS
# -----------------------------------------------
output "rds_primary_endpoint" {
  description = "서울 Aurora Writer 엔드포인트 (앱 DB 연결 주소)"
  value       = module.rds.primary_endpoint
}

output "rds_secondary_endpoint" {
  description = "도쿄 Aurora 엔드포인트 (장애 시 사용)"
  value       = module.rds.secondary_endpoint
}

output "rds_global_cluster_id" {
  description = "Global Cluster ID"
  value       = module.rds.global_cluster_id
}
