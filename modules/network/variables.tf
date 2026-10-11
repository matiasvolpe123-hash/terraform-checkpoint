variable "name" {
  description = "Prefijo usado para nombrar y etiquetar todos los recursos de red (por ejemplo: datalake-dev)."
  type        = string
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr debe ser un bloque CIDR válido, por ejemplo 10.0.0.0/16."
  }
}

variable "availability_zones" {
  description = "Lista de zonas de disponibilidad donde se crean las subredes privadas (una subred por AZ)."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Se necesitan al menos 2 zonas de disponibilidad."
  }
}

variable "private_subnet_cidrs" {
  description = "Lista de CIDRs de las subredes privadas, en el mismo orden que availability_zones."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "Se necesitan al menos 2 subredes privadas."
  }

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "Todos los valores de private_subnet_cidrs deben ser CIDRs válidos."
  }
}

variable "tags" {
  description = "Etiquetas adicionales que se aplican a todos los recursos."
  type        = map(string)
  default     = {}
}
