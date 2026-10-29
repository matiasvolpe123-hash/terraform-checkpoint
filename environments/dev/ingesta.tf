# ------------------------------------------------------------------------------
# Ingesta de eventos: Data Lake (S3) + Kinesis Data Stream + Firehose
# ------------------------------------------------------------------------------

module "datalake" {
  source = "../../modules/datalake"

  bucket_name   = var.data_bucket_name
  force_destroy = true # solo en dev: permite destruir el bucket aunque tenga archivos
}

module "kinesis" {
  source = "../../modules/kinesis"

  project                = "datalake"
  environment            = var.environment
  shard_count            = 2
  destination_bucket_arn = module.datalake.bucket_arn
  destination_prefix     = "${var.data_prefix}/"

  buffering_size_mb          = 5
  buffering_interval_seconds = 60
}

output "kinesis_stream_name" {
  description = "Nombre del Kinesis Data Stream (para el comando put-record)."
  value       = module.kinesis.stream_name
}

output "firehose_name" {
  description = "Nombre del delivery stream de Firehose."
  value       = module.kinesis.firehose_name
}

output "datalake_bucket_name" {
  description = "Bucket S3 del Data Lake donde Firehose entrega los archivos."
  value       = module.datalake.bucket_name
}

resource "aws_s3_object" "flink_application" {
  bucket       = module.datalake.bucket_name
  key          = "applications/flink/flink-kinesis-processor.jar"
  source       = var.flink_jar_path
  source_hash  = filebase64sha256(var.flink_jar_path)
  content_type = "application/java-archive"
}

module "flink" {
  source = "../../modules/flink"

  name                             = "datalake-${var.environment}-sensor-aggregation"
  aws_region                       = var.aws_region
  kinesis_stream_arn               = module.kinesis.stream_arn
  kinesis_stream_name              = module.kinesis.stream_name
  kinesis_kms_key_arn              = module.kinesis.kms_key_arn
  application_code_bucket_arn      = module.datalake.bucket_arn
  application_code_key             = aws_s3_object.flink_application.key
  application_code_object_arn      = aws_s3_object.flink_application.arn
  parallelism                      = var.flink_parallelism
  parallelism_per_kpu              = var.flink_parallelism_per_kpu
  auto_scaling_enabled             = var.flink_auto_scaling_enabled
  window_minutes                   = var.flink_window_minutes
  out_of_order_seconds             = var.flink_out_of_order_seconds
  checkpoint_interval_ms           = var.flink_checkpoint_interval_ms
  min_pause_between_checkpoints_ms = var.flink_min_pause_between_checkpoints_ms
  tags = {
    Environment = var.environment
    Project     = "data-engineering-checkpoint"
    ManagedBy   = "terraform"
  }
}

output "flink_application_name" {
  description = "Nombre de la aplicación Managed Service for Apache Flink."
  value       = module.flink.application_name
}

output "flink_application_arn" {
  value = module.flink.application_arn
}

output "flink_log_group_name" {
  value = module.flink.log_group_name
}
