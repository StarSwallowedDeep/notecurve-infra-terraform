output "cloudfront_domain"  { value = aws_cloudfront_distribution.this.domain_name }
output "cloudfront_arn"     { value = aws_cloudfront_distribution.this.arn }
output "seoul_bucket_name"  { value = aws_s3_bucket.seoul.bucket }
output "tokyo_bucket_name"  { value = aws_s3_bucket.tokyo.bucket }
