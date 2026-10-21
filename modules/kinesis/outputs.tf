output "stream_name" {
  description = "Nombre del Kinesis Data Stream (se usa en el comando put-record)."
  value       = aws_kinesis_stream.this.name
}

output "stream_arn" {
  description = "ARN del Kinesis Data Stream."
  value       = aws_kinesis_stream.this.arn
}

output "firehose_name" {
  description = "Nombre del delivery stream de Firehose."
  value       = aws_kinesis_firehose_delivery_stream.this.name
}

output "firehose_role_arn" {
  description = "ARN del rol de Firehose."
  value       = aws_iam_role.firehose.arn
}

output "kms_key_arn" {
  description = "ARN de la clave KMS que cifra el stream."
  value       = aws_kms_key.stream.arn
}

output "log_group_name" {
  description = "Log group de CloudWatch con los errores de entrega de Firehose."
  value       = aws_cloudwatch_log_group.firehose.name
}
