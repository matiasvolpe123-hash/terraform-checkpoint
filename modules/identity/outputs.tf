output "processing_role_arn" {
  description = "ARN del rol de ejecución para servicios de procesamiento de datos."
  value       = aws_iam_role.processing.arn
}

output "processing_role_name" {
  description = "Nombre del rol de ejecución para servicios de procesamiento de datos."
  value       = aws_iam_role.processing.name
}

output "processing_policy_arn" {
  description = "ARN de la política de acceso a S3 por prefijo."
  value       = aws_iam_policy.processing_s3.arn
}

output "audit_role_arn" {
  description = "ARN del rol de solo lectura para auditoría del plano de control."
  value       = aws_iam_role.audit.arn
}

output "audit_role_name" {
  description = "Nombre del rol de solo lectura para auditoría."
  value       = aws_iam_role.audit.name
}
