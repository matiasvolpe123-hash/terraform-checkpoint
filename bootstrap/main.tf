# ------------------------------------------------------------------------------
# Bootstrap del estado remoto
#
# Crea el bucket S3 (con cifrado SSE) y la tabla DynamoDB (locking) que usa
# environments/dev como backend. Se ejecuta UNA sola vez y guarda su propio
# estado en local (no puede usar un backend que todavia no existe).
# ------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  tags = {
    ManagedBy = "terraform"
    Project   = "data-engineering-checkpoint"
    Purpose   = "terraform-remote-state"
  }
}

# --- Bucket de estado ---------------------------------------------------------
resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  # Protege el estado de borrados accidentales.
  lifecycle {
    prevent_destroy = true
  }

  tags = local.tags
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Cifrado del lado del servidor (SSE-S3 / AES256).
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- Tabla de locking ---------------------------------------------------------
resource "aws_dynamodb_table" "lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.tags
}
