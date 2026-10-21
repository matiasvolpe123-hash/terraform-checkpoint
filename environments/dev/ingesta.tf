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
