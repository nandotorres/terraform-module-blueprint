output "bucket_id" {
  description = "Name of the bucket."
  value       = module.bucket.bucket_id
}

output "bucket_arn" {
  description = "ARN of the bucket."
  value       = module.bucket.bucket_arn
}

output "bucket_regional_domain_name" {
  description = "Regional domain name of the bucket."
  value       = module.bucket.bucket_regional_domain_name
}
