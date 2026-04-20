variable "stage"       { type = string }
variable "servicename" { type = string }
variable "tags"        { type = map(string) }

variable "alert_email" {
  type        = string
  description = "장애 알림 받을 이메일"
}

variable "global_cluster_id" {
  type        = string
  description = "Aurora Global Cluster ID"
}

variable "secondary_cluster_id" {
  type        = string
  description = "도쿄 Aurora 클러스터 ID"
}

variable "tokyo_rk_ec2_id" {
  type        = string
  description = "도쿄 Redis/Kafka EC2 인스턴스 ID"
}

variable "tokyo_app_ec2_ids" {
  type        = list(string)
  description = "도쿄 앱 EC2 인스턴스 ID 목록"
}

variable "tokyo_vpn_ec2_id" {
  type        = string
  description = "도쿄 VPN EC2 인스턴스 ID"
}

variable "seoul_alb_arn_suffix" {
  type        = string
  description = "서울 ALB ARN suffix (CloudWatch용)"
}

variable "seoul_health_check_id" {
  type        = string
  description = "서울 Route 53 헬스체크 ID"
}
