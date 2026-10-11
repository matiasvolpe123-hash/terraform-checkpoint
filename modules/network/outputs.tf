output "vpc_id" {
  description = "ID de la VPC creada."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "Bloque CIDR de la VPC."
  value       = aws_vpc.this.cidr_block
}

output "private_subnet_ids" {
  description = "IDs de las subredes privadas, ordenados por zona de disponibilidad."
  value       = [for az in sort(keys(aws_subnet.private)) : aws_subnet.private[az].id]
}

output "private_route_table_ids" {
  description = "IDs de las route tables de las subredes privadas."
  value       = [for az in sort(keys(aws_route_table.private)) : aws_route_table.private[az].id]
}

output "s3_gateway_endpoint_id" {
  description = "ID del S3 Gateway Endpoint."
  value       = aws_vpc_endpoint.s3.id
}

output "s3_gateway_endpoint_route_table_ids" {
  description = "Route tables a las que está asociado el S3 Gateway Endpoint (sirve para verificar la asociación)."
  value       = aws_vpc_endpoint.s3.route_table_ids
}
