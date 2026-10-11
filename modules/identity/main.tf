data "aws_caller_identity" "current" {}

locals {
  common_tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "identity"
  })

  bucket_arn = "arn:aws:s3:::${var.data_bucket_name}"

  # Si no se indican principales de auditoría, se confía en la cuenta actual.
  audit_principals = length(var.audit_trusted_principal_arns) > 0 ? var.audit_trusted_principal_arns : [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  ]
}

# ------------------------------------------------------------------------------
# Rol de ejecución para servicios de procesamiento (Lambda / Flink)
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "processing_assume_role" {
  statement {
    sid     = "AllowServiceToAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = var.processing_trusted_services
    }
  }
}

resource "aws_iam_role" "processing" {
  name               = "${var.name}-processing-execution-role"
  description        = "Rol de ejecución para servicios de procesamiento de datos (Lambda / Flink)."
  assume_role_policy = data.aws_iam_policy_document.processing_assume_role.json

  tags = merge(local.common_tags, {
    Name  = "${var.name}-processing-execution-role"
    Plane = "data"
  })
}

# Permisos mínimos: solo las tres acciones pedidas, y solo sobre el prefijo indicado.
data "aws_iam_policy_document" "processing_s3" {
  # ListBucket aplica al bucket (no a los objetos), por eso se restringe con la condición s3:prefix.
  statement {
    sid       = "ListBucketOnlyUnderPrefix"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [local.bucket_arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [var.data_prefix, "${var.data_prefix}/*"]
    }
  }

  # GetObject y PutObject aplican a objetos, limitados al prefijo.
  statement {
    sid       = "ReadWriteObjectsUnderPrefix"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${local.bucket_arn}/${var.data_prefix}/*"]
  }
}

resource "aws_iam_policy" "processing_s3" {
  name        = "${var.name}-processing-s3-prefix-access"
  description = "Permite s3:ListBucket, s3:GetObject y s3:PutObject unicamente sobre el prefijo ${var.data_prefix}."
  policy      = data.aws_iam_policy_document.processing_s3.json

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "processing_s3" {
  role       = aws_iam_role.processing.name
  policy_arn = aws_iam_policy.processing_s3.arn
}

# ------------------------------------------------------------------------------
# Rol del plano de control: solo lectura para auditoría
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "audit_assume_role" {
  statement {
    sid     = "AllowAuditorsToAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = local.audit_principals
    }
  }
}

resource "aws_iam_role" "audit" {
  name                 = "${var.name}-control-plane-audit-role"
  description          = "Rol de solo lectura para auditoria del plano de control."
  assume_role_policy   = data.aws_iam_policy_document.audit_assume_role.json
  max_session_duration = 3600

  tags = merge(local.common_tags, {
    Name  = "${var.name}-control-plane-audit-role"
    Plane = "control"
  })
}

# Politica administrada por AWS pensada para auditoria: solo permisos de lectura de metadatos.
resource "aws_iam_role_policy_attachment" "audit_security_audit" {
  role       = aws_iam_role.audit.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}
