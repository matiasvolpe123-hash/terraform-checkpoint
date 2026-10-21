variable "bucket_name" {
  description = "Nombre del bucket S3 del Data Lake. Debe ser único a nivel global."
  type        = string
}

variable "force_destroy" {
  description = "Si es true, permite destruir el bucket aunque tenga objetos. Útil en dev, peligroso en prod."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Etiquetas adicionales que se aplican a todos los recursos."
  type        = map(string)
  default     = {}
}
