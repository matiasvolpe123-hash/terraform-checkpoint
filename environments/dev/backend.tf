# ------------------------------------------------------------------------------
# Backend remoto: estado en S3 (cifrado) + locking en DynamoDB.
#
# IMPORTANTE: el bucket y la tabla los crea el proyecto ../../bootstrap.
# Los valores de "bucket" y "dynamodb_table" deben coincidir con los que usaste
# alli. Un bloque backend no admite variables, por eso van escritos a mano.
# ------------------------------------------------------------------------------
terraform {
  backend "s3" {
    bucket         = "tfstate-683590131550-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true # cifrado SSE del lado del servidor
    dynamodb_table = "terraform-state-lock"
  }
}
