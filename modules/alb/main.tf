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
# ALB 보안 그룹
# -----------------------------------------------
resource "aws_security_group" "alb" {
  name   = "${local.prefix}-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.prefix}-alb-sg" })
}

# -----------------------------------------------
# ALB
# -----------------------------------------------
resource "aws_lb" "this" {
  name               = "${local.prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets

  enable_deletion_protection = false

  tags = merge(var.tags, { Name = "${local.prefix}-alb" })
}

# -----------------------------------------------
# 타겟 그룹 - 백엔드 (8080)
# -----------------------------------------------
resource "aws_lb_target_group" "app" {
  name     = "${local.prefix}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(var.tags, { Name = "${local.prefix}-tg" })
}

# -----------------------------------------------
# 타겟 그룹 - 어드민 백엔드 (8081)
# -----------------------------------------------
resource "aws_lb_target_group" "admin" {
  name     = "${local.prefix}-admin-tg"
  port     = 8081
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(var.tags, { Name = "${local.prefix}-admin-tg" })
}

# -----------------------------------------------
# 타겟 등록 - 백엔드
# -----------------------------------------------
resource "aws_lb_target_group_attachment" "app" {
  count            = length(var.target_instance_ids)
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = var.target_instance_ids[count.index]
  port             = var.app_port
}

# -----------------------------------------------
# 타겟 등록 - 어드민 백엔드
# -----------------------------------------------
resource "aws_lb_target_group_attachment" "admin" {
  count            = length(var.target_instance_ids)
  target_group_arn = aws_lb_target_group.admin.arn
  target_id        = var.target_instance_ids[count.index]
  port             = 8081
}

# -----------------------------------------------
# HTTP 리스너 → HTTPS 리다이렉트
# -----------------------------------------------
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# -----------------------------------------------
# HTTPS 리스너 - 기본은 백엔드(8080)로
# -----------------------------------------------
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# -----------------------------------------------
# 리스너 규칙 - api-admin 호스트는 어드민 타겟으로
# -----------------------------------------------
resource "aws_lb_listener_rule" "admin" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  condition {
    host_header {
      values = ["api-admin.${var.domain_name}"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.admin.arn
  }
}
