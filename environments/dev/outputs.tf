output "vpc_id" {
  description = "ID de la VPC del entorno."
  value       = module.network.vpc_id
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas."
  value       = module.network.private_subnet_ids
}

output "s3_gateway_endpoint_id" {
  description = "ID del S3 Gateway Endpoint."
  value       = module.network.s3_gateway_endpoint_id
}

output "s3_gateway_endpoint_route_table_ids" {
  description = "Route tables asociadas al S3 Gateway Endpoint (deben coincidir con las de las subredes privadas)."
  value       = module.network.s3_gateway_endpoint_route_table_ids
}

output "private_route_table_ids" {
  description = "Route tables de las subredes privadas."
  value       = module.network.private_route_table_ids
}

output "processing_role_arn" {
  description = "ARN del rol de ejecución para procesamiento de datos."
  value       = module.identity.processing_role_arn
}

output "audit_role_arn" {
  description = "ARN del rol de auditoría de solo lectura."
  value       = module.identity.audit_role_arn
}
