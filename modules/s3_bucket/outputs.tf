output "bucket_id" {
  description = "Name of the bucket."
  value       = module.bucket.s3_bucket_id
}

output "bucket_arn" {
  description = "ARN of the bucket."
  value       = module.bucket.s3_bucket_arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the bucket."
  value       = module.bucket.s3_bucket_bucket_regional_domain_name
}

output "versioning_status" {
  description = "Versioning status of the bucket. Always Enabled."
  value       = module.bucket.aws_s3_bucket_versioning_status
}

output "tags" {
  description = "Tags applied to the bucket, including ManagedBy and Module."
  value       = module.bucket.s3_bucket_tags
}

output "lifecycle_rules" {
  description = "Lifecycle rules applied to the bucket. Null when expiration_days is null."
  value       = module.bucket.s3_bucket_lifecycle_configuration_rules
}
