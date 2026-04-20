output "primary_endpoint" {
  description = "서울 Aurora Writer 엔드포인트 (앱에서 쓰기용)"
  value       = aws_rds_cluster.primary.endpoint
}

output "primary_reader_endpoint" {
  description = "서울 Aurora Reader 엔드포인트 (읽기용)"
  value       = aws_rds_cluster.primary.reader_endpoint
}

output "secondary_endpoint" {
  description = "도쿄 Aurora 엔드포인트 (장애 시 승격 후 사용)"
  value       = aws_rds_cluster.secondary.endpoint
}

output "global_cluster_id" {
  description = "Global Cluster ID (장애 시 승격에 필요)"
  value       = aws_rds_global_cluster.this.id
}
