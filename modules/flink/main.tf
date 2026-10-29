data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["kinesisanalytics.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flink" {
  name               = "${var.name}-flink-execution-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "flink" {
  statement {
    sid = "ReadInputStream"
    actions = ["kinesis:DescribeStream", "kinesis:DescribeStreamSummary", "kinesis:GetRecords",
    "kinesis:GetShardIterator", "kinesis:ListShards", "kinesis:SubscribeToShard"]
    resources = [var.kinesis_stream_arn]
  }
  statement {
    sid       = "ListKinesisStreams"
    actions   = ["kinesis:ListStreams"]
    resources = ["*"]
  }
  statement {
    sid       = "ReadApplicationCode"
    actions   = ["s3:GetObject", "s3:GetObjectVersion"]
    resources = [var.application_code_object_arn]
  }
  statement {
    sid       = "DecryptInputStream"
    actions   = ["kms:Decrypt"]
    resources = [var.kinesis_kms_key_arn]
  }
  statement {
    sid       = "WriteApplicationLogs"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.flink.arn}:*"]
  }
}

resource "aws_iam_role_policy" "flink" {
  name   = "${var.name}-flink-runtime"
  role   = aws_iam_role.flink.id
  policy = data.aws_iam_policy_document.flink.json
}

resource "aws_cloudwatch_log_group" "flink" {
  name              = "/aws/kinesis-analytics/${var.name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_kinesisanalyticsv2_application" "this" {
  name                   = var.name
  runtime_environment    = "FLINK-1_18"
  service_execution_role = aws_iam_role.flink.arn
  application_mode       = "STREAMING"

  application_configuration {
    application_code_configuration {
      code_content_type = "ZIPFILE"
      code_content {
        s3_content_location {
          bucket_arn     = var.application_code_bucket_arn
          file_key       = var.application_code_key
          object_version = var.application_code_object_version
        }
      }
    }
    flink_application_configuration {
      checkpoint_configuration {
        configuration_type            = "CUSTOM"
        checkpointing_enabled         = true
        checkpoint_interval           = var.checkpoint_interval_ms
        min_pause_between_checkpoints = var.min_pause_between_checkpoints_ms
      }
      monitoring_configuration {
        configuration_type = "CUSTOM"
        log_level          = "INFO"
        metrics_level      = "APPLICATION"
      }
      parallelism_configuration {
        configuration_type   = "CUSTOM"
        parallelism          = var.parallelism
        parallelism_per_kpu  = var.parallelism_per_kpu
        auto_scaling_enabled = var.auto_scaling_enabled
      }
    }
    environment_properties {
      property_group {
        property_group_id = "FlinkApplicationProperties"
        property_map = {
          STREAM_NAME          = var.kinesis_stream_name
          AWS_REGION           = var.aws_region
          PARALLELISM          = tostring(var.parallelism)
          WINDOW_MINUTES       = tostring(var.window_minutes)
          OUT_OF_ORDER_SECONDS = tostring(var.out_of_order_seconds)
        }
      }
    }
  }

  cloudwatch_logging_options {
    log_stream_arn = aws_cloudwatch_log_stream.flink.arn
  }

  tags       = var.tags
  depends_on = [aws_iam_role_policy.flink]
}

resource "aws_cloudwatch_log_stream" "flink" {
  name           = "application"
  log_group_name = aws_cloudwatch_log_group.flink.name
}
