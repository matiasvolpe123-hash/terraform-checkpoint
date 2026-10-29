variable "aws_region" {
  description = "Región de AWS donde se despliega el entorno."
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Nombre del entorno. Se usa como prefijo de los recursos."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDRs de las subredes privadas (una por zona de disponibilidad)."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "data_bucket_name" {
  description = "Bucket S3 de datos sobre el que el rol de procesamiento tendrá acceso (no lo crea este entorno)."
  type        = string
}

variable "data_prefix" {
  description = "Prefijo dentro del bucket de datos al que se limita el acceso del rol de procesamiento."
  type        = string
  default     = "streaming/raw"
}

variable "audit_trusted_principal_arns" {
  description = "ARNs autorizados a asumir el rol de auditoría. Vacío = cuenta actual."
  type        = list(string)
  default     = []
}

variable "flink_jar_path" {
  description = "Ruta al JAR sombreado generado con Maven antes de ejecutar Terraform (relativa a environments/dev)."
  type        = string
  default     = "../../flink/target/flink-kinesis-processor.jar"
}

variable "flink_parallelism" {
  description = "Paralelismo global inicial del job; se alinea con los dos shards del stream."
  type        = number
  default     = 2
}

variable "flink_parallelism_per_kpu" {
  description = "Operadores paralelos permitidos por KPU para dimensionar Managed Flink."
  type        = number
  default     = 1
}

variable "flink_auto_scaling_enabled" {
  type    = bool
  default = false
}

variable "flink_window_minutes" {
  description = "Duración de ventana de evento en minutos."
  type        = number
  default     = 1
}

variable "flink_out_of_order_seconds" {
  description = "Tolerancia de desorden para watermarks."
  type        = number
  default     = 10
}

variable "flink_checkpoint_interval_ms" {
  type    = number
  default = 60000
}

variable "flink_min_pause_between_checkpoints_ms" {
  type    = number
  default = 30000
}
