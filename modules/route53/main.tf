terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------
# Route 53 헬스체크 - 서울 ALB
# -----------------------------------------------
resource "aws_route53_health_check" "seoul" {
  fqdn              = var.seoul_alb_dns
  port              = 443
  type              = "HTTPS"
  resource_path     = "/actuator/health"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(var.tags, { Name = "healthcheck-seoul-alb" })
}

# -----------------------------------------------
# Route 53 헬스체크 - 도쿄 ALB
# -----------------------------------------------
resource "aws_route53_health_check" "tokyo" {
  fqdn              = var.tokyo_alb_dns
  port              = 443
  type              = "HTTPS"
  resource_path     = "/actuator/health"
  failure_threshold = 3
  request_interval  = 30

  tags = merge(var.tags, { Name = "healthcheck-tokyo-alb" })
}

# -----------------------------------------------
# Route 53 레코드 - 서울 (Primary)
# -----------------------------------------------
resource "aws_route53_record" "seoul" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = "seoul-primary"
  health_check_id = aws_route53_health_check.seoul.id

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = var.seoul_alb_dns
    zone_id                = var.seoul_alb_zone_id
    evaluate_target_health = true
  }
}

# -----------------------------------------------
# Route 53 레코드 - 도쿄 (Secondary)
# -----------------------------------------------
resource "aws_route53_record" "tokyo" {
  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  set_identifier = "tokyo-secondary"
  health_check_id = aws_route53_health_check.tokyo.id

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = var.tokyo_alb_dns
    zone_id                = var.tokyo_alb_zone_id
    evaluate_target_health = true
  }
}

# -----------------------------------------------
# api 서브도메인 - 서울 (Primary)
# -----------------------------------------------
resource "aws_route53_record" "api_seoul" {
  zone_id = var.hosted_zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  set_identifier = "api-seoul-primary"
  health_check_id = aws_route53_health_check.seoul.id

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = var.seoul_alb_dns
    zone_id                = var.seoul_alb_zone_id
    evaluate_target_health = true
  }
}

# -----------------------------------------------
# api 서브도메인 - 도쿄 (Secondary)
# -----------------------------------------------
resource "aws_route53_record" "api_tokyo" {
  zone_id = var.hosted_zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  set_identifier = "api-tokyo-secondary"
  health_check_id = aws_route53_health_check.tokyo.id

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = var.tokyo_alb_dns
    zone_id                = var.tokyo_alb_zone_id
    evaluate_target_health = true
  }
}
