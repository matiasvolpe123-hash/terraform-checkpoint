variable "project" {
  description = "Nombre corto del proyecto. Forma parte del nombre del stream (por ejemplo: datalake)."
  type        = string
}

variable "environment" {
  description = "Nombre del entorno (dev, prod...). Forma parte del nombre del stream y de las etiquetas."
  type        = string
}

variable "shard_count" {
  description = "Cantidad de shards del Kinesis Data Stream en modo PROVISIONED."
  type        = number
  default     = 2

  validation {
    condition     = var.shard_count >= 2
    error_message = "shard_count debe ser al menos 2."
  }
}

variable "retention_period_hours" {
  description = "Horas que Kinesis retiene los registros (24 a 8760)."
  type        = number
  default     = 24

  validation {
    condition     = var.retention_period_hours >= 24 && var.retention_period_hours <= 8760
    error_message = "retention_period_hours debe estar entre 24 y 8760."
  }
}

variable "destination_bucket_arn" {
  description = "ARN del bucket S3 (Data Lake) donde Firehose entrega los datos."
  type        = string
}

variable "destination_prefix" {
  description = "Prefijo dentro del bucket donde Firehose escribe los archivos, terminado en '/'."
  type        = string
  default     = "streaming/raw/"

  validation {
    condition     = endswith(var.destination_prefix, "/") && !startswith(var.destination_prefix, "/")
    error_message = "destination_prefix debe terminar en '/' y no empezar con '/'."
  }
}

variable "buffering_size_mb" {
  description = "Tamaño del buffer de Firehose en MB antes de entregar a S3."
  type        = number
  default     = 5
}

variable "buffering_interval_seconds" {
  description = "Intervalo del buffer de Firehose en segundos antes de entregar a S3."
  type        = number
  default     = 60
}

variable "log_retention_days" {
  description = "Días de retención de los logs de Firehose en CloudWatch."
  type        = number
  default     = 7
}

variable "tags" {
  description = "Etiquetas adicionales que se aplican a todos los recursos."
  type        = map(string)
  default     = {}
}
