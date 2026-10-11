variable "region" {
  type        = string
  description = "AWS region. LocalStack uses us-east-1."
  default     = "us-east-1"
}

variable "localstack_endpoint" {
  type        = string
  description = "LocalStack endpoint."
  default     = "http://localhost:4566"
}

variable "bucket_name" {
  type        = string
  description = "Bucket name."
  default     = "example-bucket"
}

variable "force_destroy" {
  type        = bool
  description = "Delete objects on destroy."
  default     = true
}

variable "expiration_days" {
  type        = number
  description = "Object expiration in days. Null omits the lifecycle rule."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Caller tags. Environment and Owner are required."
  default = {
    Environment = "test"
    Owner       = "platform"
  }
}
