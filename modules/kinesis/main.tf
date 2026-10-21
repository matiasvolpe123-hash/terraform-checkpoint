data "aws_caller_identity" "current" {}

locals {
  name = "${var.project}-${var.environment}"

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "kinesis"
  })

  log_group_name  = "/aws/kinesisfirehose/${local.name}-to-s3"
  log_stream_name = "S3Delivery"
}

# ------------------------------------------------------------------------------
# KMS: clave propia para cifrar el stream (encryption_type = "KMS")
# ------------------------------------------------------------------------------
resource "aws_kms_key" "stream" {
  description             = "Cifrado del Kinesis Data Stream ${local.name}"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = merge(local.common_tags, {
    Name = "${local.name}-stream-key"
  })
}

resource "aws_kms_alias" "stream" {
  name          = "alias/${local.name}-stream"
  target_key_id = aws_kms_key.stream.key_id
}

# ------------------------------------------------------------------------------
# Kinesis Data Stream (modo PROVISIONED, 2 shards o más, cifrado KMS)
# El nombre sale de las variables project y environment.
# ------------------------------------------------------------------------------
resource "aws_kinesis_stream" "this" {
  name             = "${local.name}-events"
  shard_count      = var.shard_count
  retention_period = var.retention_period_hours

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  encryption_type = "KMS"
  kms_key_id      = aws_kms_key.stream.arn

  tags = merge(local.common_tags, {
    Name = "${local.name}-events"
  })
}

# ------------------------------------------------------------------------------
# CloudWatch Logs para los errores de entrega de Firehose
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "firehose" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

resource "aws_cloudwatch_log_stream" "firehose" {
  name           = local.log_stream_name
  log_group_name = aws_cloudwatch_log_group.firehose.name
}

# ------------------------------------------------------------------------------
# Rol de Firehose: leer del stream, escribir en S3 y escribir logs
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "firehose_assume_role" {
  statement {
    sid     = "AllowFirehoseToAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    # Evita que otra cuenta use este rol a través de Firehose (confused deputy).
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "firehose" {
  name               = "${local.name}-firehose-delivery-role"
  description        = "Rol de Firehose para leer de Kinesis, escribir en S3 y registrar logs."
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${local.name}-firehose-delivery-role"
  })
}

data "aws_iam_policy_document" "firehose" {
  statement {
    sid    = "ReadFromKinesisStream"
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards",
    ]
    resources = [aws_kinesis_stream.this.arn]
  }

  # Necesario porque el stream está cifrado con una clave propia.
  statement {
    sid       = "DecryptStreamRecords"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.stream.arn]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["kinesis.${data.aws_region.current.name}.amazonaws.com"]
    }
  }

  statement {
    sid    = "WriteToDataLakeBucket"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]
    resources = [
      var.destination_bucket_arn,
      "${var.destination_bucket_arn}/${var.destination_prefix}*",
    ]
  }

  statement {
    sid       = "WriteDeliveryLogs"
    effect    = "Allow"
    actions   = ["logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.firehose.arn}:log-stream:${local.log_stream_name}"]
  }
}

data "aws_region" "current" {}

resource "aws_iam_policy" "firehose" {
  name        = "${local.name}-firehose-delivery-policy"
  description = "Permisos minimos de Firehose: leer del stream, escribir en el prefijo del Data Lake y escribir logs."
  policy      = data.aws_iam_policy_document.firehose.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "firehose" {
  role       = aws_iam_role.firehose.name
  policy_arn = aws_iam_policy.firehose.arn
}

# ------------------------------------------------------------------------------
# Kinesis Data Firehose: source = Kinesis stream, destination = S3
# ------------------------------------------------------------------------------
resource "aws_kinesis_firehose_delivery_stream" "this" {
  name        = "${local.name}-to-s3"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.this.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = var.destination_bucket_arn
    prefix     = var.destination_prefix

    # Buffering agresivo para desarrollo: se entrega cada 5 MB o cada 60 s.
    buffering_size     = var.buffering_size_mb
    buffering_interval = var.buffering_interval_seconds

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = aws_cloudwatch_log_stream.firehose.name
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name}-to-s3"
  })

  # El rol necesita sus permisos antes de que Firehose intente usarlo.
  depends_on = [aws_iam_role_policy_attachment.firehose]
}
