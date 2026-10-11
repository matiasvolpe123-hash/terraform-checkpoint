variable "name" {
  description = "Prefijo usado para nombrar los roles y políticas (por ejemplo: datalake-dev)."
  type        = string
}

variable "data_bucket_name" {
  description = "Nombre del bucket S3 sobre el que el rol de procesamiento puede operar. El bucket debe existir o crearse fuera de este módulo."
  type        = string
}

variable "data_prefix" {
  description = "Prefijo (carpeta) dentro del bucket al que se limita el acceso, sin barra inicial. Ejemplo: 'streaming/raw'."
  type        = string

  validation {
    condition     = length(var.data_prefix) > 0 && !startswith(var.data_prefix, "/") && !can(regex("\\*", var.data_prefix))
    error_message = "data_prefix no puede estar vacío, no debe empezar con '/' y no puede contener '*'."
  }
}

variable "processing_trusted_services" {
  description = "Servicios de AWS autorizados a asumir el rol de procesamiento. Por defecto Lambda y Managed Service for Apache Flink."
  type        = list(string)
  default     = ["lambda.amazonaws.com", "kinesisanalytics.amazonaws.com"]
}

variable "audit_trusted_principal_arns" {
  description = "ARNs de usuarios o roles autorizados a asumir el rol de auditoría. Si queda vacío, se confía en la raíz de la cuenta actual (cualquier identidad de la cuenta con permiso sts:AssumeRole)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Etiquetas adicionales que se aplican a todos los recursos."
  type        = map(string)
  default     = {}
}
