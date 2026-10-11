variable "aws_region" {
  description = "Región de AWS donde se crean el bucket de estado y la tabla de locking."
  type        = string
  default     = "us-east-2"
}

variable "state_bucket_name" {
  description = "Nombre del bucket S3 para el estado remoto. Debe ser único a nivel global (ej: tfstate-matias-dev-123456)."
  type        = string
}

variable "lock_table_name" {
  description = "Nombre de la tabla DynamoDB usada para el locking del estado."
  type        = string
  default     = "terraform-state-lock"
}
