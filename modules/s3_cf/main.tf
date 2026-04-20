terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [aws.us_east_1, aws.tokyo]
    }
  }
}

locals {
  prefix = "${var.stage}-${var.servicename}"
}

# -----------------------------------------------
# S3 버킷 - 서울 (Primary)
# -----------------------------------------------
resource "aws_s3_bucket" "seoul" {
  bucket        = "${local.prefix}-frontend-seoul"
  force_destroy = true
  tags          = merge(var.tags, { Name = "${local.prefix}-frontend-seoul" })
}

resource "aws_s3_bucket_versioning" "seoul" {
  bucket = aws_s3_bucket.seoul.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "seoul" {
  bucket                  = aws_s3_bucket.seoul.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------
# S3 버킷 - 도쿄 (CRR 대상)
# -----------------------------------------------
resource "aws_s3_bucket" "tokyo" {
  provider      = aws.tokyo
  bucket        = "${local.prefix}-frontend-tokyo"
  force_destroy = true
  tags          = merge(var.tags, { Name = "${local.prefix}-frontend-tokyo" })
}

resource "aws_s3_bucket_versioning" "tokyo" {
  provider = aws.tokyo
  bucket   = aws_s3_bucket.tokyo.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "tokyo" {
  provider                = aws.tokyo
  bucket                  = aws_s3_bucket.tokyo.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------
# CRR IAM Role
# -----------------------------------------------
resource "aws_iam_role" "crr" {
  name = "${local.prefix}-s3-crr-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "crr" {
  name = "${local.prefix}-s3-crr-policy"
  role = aws_iam_role.crr.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
        Resource = [aws_s3_bucket.seoul.arn]
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
        Resource = ["${aws_s3_bucket.seoul.arn}/*"]
      },
      {
        Effect = "Allow"
        Action = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
        Resource = ["${aws_s3_bucket.tokyo.arn}/*"]
      }
    ]
  })
}

# -----------------------------------------------
# CRR 복제 규칙
# -----------------------------------------------
resource "aws_s3_bucket_replication_configuration" "crr" {
  bucket = aws_s3_bucket.seoul.id
  role   = aws_iam_role.crr.arn

  rule {
    id     = "replicate-all-to-tokyo"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.tokyo.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [aws_s3_bucket_versioning.seoul, aws_s3_bucket_versioning.tokyo]
}

# -----------------------------------------------
# CloudFront OAC (Origin Access Control)
# -----------------------------------------------
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${local.prefix}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# -----------------------------------------------
# S3 버킷 정책 - CloudFront OAC 허용
# -----------------------------------------------
resource "aws_s3_bucket_policy" "seoul" {
  bucket = aws_s3_bucket.seoul.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontOAC"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.seoul.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
        }
      }
    }]
  })
}

resource "aws_s3_bucket_policy" "tokyo" {
  provider = aws.tokyo
  bucket   = aws_s3_bucket.tokyo.id
  policy   = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontOAC"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.tokyo.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
        }
      }
    }]
  })
}

# -----------------------------------------------
# CloudFront 배포 (Origin Group으로 자동 장애 전환)
# -----------------------------------------------
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  default_root_object = "index.html"
  comment             = "${local.prefix} frontend DR distribution"

  # Origin 1: 서울 S3 (Primary)
  origin {
    domain_name              = aws_s3_bucket.seoul.bucket_regional_domain_name
    origin_id                = "s3-seoul"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  # Origin 2: 도쿄 S3 (Failover)
  origin {
    domain_name              = aws_s3_bucket.tokyo.bucket_regional_domain_name
    origin_id                = "s3-tokyo"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  # Origin Group: 서울 실패 시 → 도쿄 자동 전환
  origin_group {
    origin_id = "s3-origin-group"

    failover_criteria {
      status_codes = [500, 502, 503, 504, 403, 404]
    }

    member { origin_id = "s3-seoul" }
    member { origin_id = "s3-tokyo" }
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin-group"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # SPA 라우팅 (React/Vue 등)
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(var.tags, { Name = "${local.prefix}-cf" })
}
