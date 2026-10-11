mock_provider "aws" {
  override_during = plan

  # Upstream renders the bucket policy from this data source. The mock must be JSON.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  bucket_name = "example-bucket"
  tags = {
    Environment = "test"
    Owner       = "platform"
  }
}

run "secure_defaults" {
  command = apply

  assert {
    condition     = output.versioning_status == "Enabled"
    error_message = "Versioning must be enabled."
  }

  assert {
    condition = (
      output.tags["Environment"] == "test" &&
      output.tags["Owner"] == "platform" &&
      output.tags["ManagedBy"] == "terraform" &&
      output.tags["Module"] == "s3_bucket"
    )
    error_message = "Bucket tags must keep the caller tags and the module-owned ManagedBy and Module tags."
  }

  assert {
    condition     = output.lifecycle_rules == null
    error_message = "Lifecycle rules must be omitted when expiration_days is null."
  }
}

run "lifecycle_rule_expires_objects" {
  command = apply

  variables {
    expiration_days = 7
  }

  assert {
    condition     = length(output.lifecycle_rules) == 1
    error_message = "Setting expiration_days must publish one lifecycle rule."
  }

  assert {
    condition     = one(output.lifecycle_rules).expiration[0].days == 7
    error_message = "Lifecycle expiration must use the configured number of days."
  }
}
