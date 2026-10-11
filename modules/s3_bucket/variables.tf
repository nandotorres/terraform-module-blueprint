variable "bucket_name" {
  type        = string
  description = "Globally unique bucket name. Lowercase letters, numbers, dots, and hyphens, 3-63 characters, starting and ending with a letter or number."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters and contain only lowercase letters, numbers, dots, and hyphens, and must start and end with a letter or number."
  }
}

variable "force_destroy" {
  type        = bool
  description = "Delete objects when destroying the bucket."
  default     = false
}

variable "expiration_days" {
  type        = number
  description = "Expire current object versions after this many days. Null omits the lifecycle configuration."
  default     = null

  validation {
    condition     = var.expiration_days == null || (var.expiration_days >= 1 && var.expiration_days <= 3650)
    error_message = "expiration_days must be null or a whole number from 1 to 3650."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the bucket. Environment and Owner are required and must be non-empty. The module sets ManagedBy and Module itself."

  validation {
    condition = (
      try(var.tags["Environment"], "") != "" &&
      try(var.tags["Owner"], "") != ""
    )
    error_message = "tags must include non-empty Environment and Owner values."
  }
}
