output "state_bucket_name" {
  description = "Bucket S3 donde se guarda el estado remoto."
  value       = aws_s3_bucket.state.id
}

output "lock_table_name" {
  description = "Tabla DynamoDB usada para el locking."
  value       = aws_dynamodb_table.lock.name
}
