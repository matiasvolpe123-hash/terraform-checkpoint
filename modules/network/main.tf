data "aws_region" "current" {}

locals {
  common_tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "network"
  })

  # Mapa AZ => CIDR para poder usar for_each con claves estables.
  private_subnets = zipmap(var.availability_zones, var.private_subnet_cidrs)
}

# ------------------------------------------------------------------------------
# VPC
# ------------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  # Cada AZ necesita su CIDR: las dos listas deben tener el mismo largo.
  lifecycle {
    precondition {
      condition     = length(var.availability_zones) == length(var.private_subnet_cidrs)
      error_message = "availability_zones y private_subnet_cidrs deben tener la misma cantidad de elementos."
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.name}-vpc"
  })
}

# Se vacía el security group por defecto (sin reglas de entrada ni salida)
# para que nada quede abierto sin querer.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-default-sg-locked"
  })
}

# ------------------------------------------------------------------------------
# Subredes privadas (una por AZ)
# No se crea Internet Gateway ni NAT Gateway: no hay ruta hacia internet.
# ------------------------------------------------------------------------------
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = each.value
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = "${var.name}-private-${each.key}"
    Tier = "private"
  })
}

# Una route table por subred privada. Solo tiene la ruta local de la VPC;
# el endpoint de S3 agrega su propia ruta (prefix list) automáticamente.
resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.name}-private-rt-${each.key}"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# ------------------------------------------------------------------------------
# S3 Gateway Endpoint, asociado a TODAS las route tables privadas
# ------------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for rt in aws_route_table.private : rt.id]

  tags = merge(local.common_tags, {
    Name = "${var.name}-s3-gateway-endpoint"
  })
}
