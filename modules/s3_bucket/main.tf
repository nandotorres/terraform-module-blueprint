locals {
  tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "s3_bucket"
  })

  lifecycle_rules = var.expiration_days == null ? [] : [
    {
      id     = "expire-objects"
      status = "Enabled"
      filter = {
        prefix = ""
      }
      expiration = {
        days = var.expiration_days
      }
    }
  ]
}

module "bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.16.2"

  bucket        = var.bucket_name
  force_destroy = var.force_destroy

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  # skip_destroy defaults to true upstream, which leaves the public access block behind on destroy.
  attach_public_policy             = true
  block_public_acls                = true
  block_public_policy              = true
  ignore_public_acls               = true
  restrict_public_buckets          = true
  skip_destroy_public_access_block = false

  attach_deny_insecure_transport_policy = true

  lifecycle_rule = local.lifecycle_rules
  tags           = local.tags
}
