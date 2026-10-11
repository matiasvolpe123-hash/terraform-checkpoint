provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "data-engineering-checkpoint"
      ManagedBy   = "terraform"
    }
  }
}

# Las dos primeras zonas de disponibilidad disponibles en la región.
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "datalake-${var.environment}"
  azs  = slice(data.aws_availability_zones.available.names, 0, length(var.private_subnet_cidrs))
}

module "network" {
  source = "../../modules/network"

  name                 = local.name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = local.azs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "identity" {
  source = "../../modules/identity"

  name                         = local.name
  data_bucket_name             = var.data_bucket_name
  data_prefix                  = var.data_prefix
  audit_trusted_principal_arns = var.audit_trusted_principal_arns
}
