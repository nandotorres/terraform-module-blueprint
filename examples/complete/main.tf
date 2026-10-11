provider "aws" {
  region                      = var.region
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam = var.localstack_endpoint
    s3  = var.localstack_endpoint
    sts = var.localstack_endpoint
  }
}

module "bucket" {
  source = "../../modules/s3_bucket"

  bucket_name     = var.bucket_name
  force_destroy   = var.force_destroy
  expiration_days = var.expiration_days
  tags            = var.tags
}
