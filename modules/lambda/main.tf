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
# SNS 토픽 (장애 알림용 - 이메일)
# -----------------------------------------------
resource "aws_sns_topic" "dr_alert" {
  name = "${local.prefix}-dr-alert"
  tags = var.tags
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.dr_alert.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# -----------------------------------------------
# Lambda IAM Role
# -----------------------------------------------
resource "aws_iam_role" "lambda_dr" {
  name = "${local.prefix}-lambda-dr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_dr" {
  name = "${local.prefix}-lambda-dr-policy"
  role = aws_iam_role.lambda_dr.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # CloudWatch 로그 기록
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        # Aurora Global DB 장애 조치
        Effect = "Allow"
        Action = [
          "rds:FailoverGlobalCluster",
          "rds:DescribeGlobalClusters",
          "rds:DescribeDBClusters"
        ]
        Resource = "*"
      },
      {
        # 도쿄 EC2에 SSM 명령 전송
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ]
        Resource = "*"
      },
      {
        # SNS 알림 전송
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = aws_sns_topic.dr_alert.arn
      },
      {
        # STS (계정 ID 조회)
        Effect   = "Allow"
        Action   = ["sts:GetCallerIdentity"]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------
# Lambda 함수
# -----------------------------------------------
resource "aws_lambda_function" "dr" {
  filename         = "${path.module}/dr_handler.zip"
  function_name    = "${local.prefix}-dr-handler"
  role             = aws_iam_role.lambda_dr.arn
  handler          = "dr_handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 60

  environment {
    variables = {
      GLOBAL_CLUSTER_ID    = var.global_cluster_id
      SECONDARY_CLUSTER_ID = var.secondary_cluster_id
      TOKYO_RK_EC2_ID      = var.tokyo_rk_ec2_id
      SNS_TOPIC_ARN        = aws_sns_topic.dr_alert.arn
    }
  }

  tags = merge(var.tags, { Name = "${local.prefix}-dr-handler" })
}

# -----------------------------------------------
# CloudWatch Alarm - 서울 ALB 5xx 에러
# -----------------------------------------------
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.prefix}-alb-5xx-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 30
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "서울 ALB 5xx 에러 급증 - DR 자동 전환 트리거"

  dimensions = {
    LoadBalancer = var.seoul_alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.dr_alert.arn]
  ok_actions    = [aws_sns_topic.dr_alert.arn]

  tags = var.tags
}

# -----------------------------------------------
# CloudWatch Alarm → Lambda 트리거
# EventBridge Rule로 Route 53 헬스체크 실패 감지
# -----------------------------------------------
resource "aws_cloudwatch_event_rule" "route53_health_fail" {
  name        = "${local.prefix}-r53-health-fail"
  description = "Route 53 헬스체크 실패 시 DR Lambda 트리거"

  event_pattern = jsonencode({
    source      = ["aws.route53"]
    detail-type = ["Route 53 Health Check Status Changed"]
    detail = {
      status           = ["UNHEALTHY"]
      healthCheckId    = [var.seoul_health_check_id]
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.route53_health_fail.name
  target_id = "dr-lambda"
  arn       = aws_lambda_function.dr.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dr.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.route53_health_fail.arn
}
