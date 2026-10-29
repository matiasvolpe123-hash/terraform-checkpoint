output "bucket_name" {
  description = "Nombre del bucket del Data Lake."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN del bucket del Data Lake."
  value       = aws_s3_bucket.this.arn
}
