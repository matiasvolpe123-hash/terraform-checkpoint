variable "name" { type = string }
variable "aws_region" { type = string }
variable "kinesis_stream_arn" { type = string }
variable "kinesis_stream_name" { type = string }
variable "kinesis_kms_key_arn" { type = string }
variable "application_code_bucket_arn" { type = string }
variable "application_code_key" { type = string }
variable "application_code_object_arn" { type = string }
variable "application_code_object_version" {
  type    = string
  default = null
}
variable "parallelism" {
  type    = number
  default = 2
}
variable "parallelism_per_kpu" {
  type    = number
  default = 1
}
variable "auto_scaling_enabled" {
  type    = bool
  default = false
}
variable "window_minutes" {
  type    = number
  default = 1
}
variable "out_of_order_seconds" {
  type    = number
  default = 10
}
variable "checkpoint_interval_ms" {
  type    = number
  default = 60000
}
variable "min_pause_between_checkpoints_ms" {
  type    = number
  default = 30000
}
variable "log_retention_days" {
  type    = number
  default = 14
}
variable "tags" {
  type    = map(string)
  default = {}
}
