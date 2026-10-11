mock_provider "aws" {
  override_during = plan

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  tags = {
    Environment = "test"
    Owner       = "platform"
  }
}

run "rejects_short_bucket_name" {
  command = plan

  variables {
    bucket_name = "ab"
  }

  expect_failures = [
    var.bucket_name,
  ]
}

run "rejects_uppercase_bucket_name" {
  command = plan

  variables {
    bucket_name = "Example-Bucket"
  }

  expect_failures = [
    var.bucket_name,
  ]
}

run "rejects_missing_owner_tag" {
  command = plan

  variables {
    bucket_name = "example-bucket"
    tags = {
      Environment = "test"
    }
  }

  expect_failures = [
    var.tags,
  ]
}

run "rejects_empty_environment_tag" {
  command = plan

  variables {
    bucket_name = "example-bucket"
    tags = {
      Environment = ""
      Owner       = "platform"
    }
  }

  expect_failures = [
    var.tags,
  ]
}

run "rejects_expiration_days_below_one" {
  command = plan

  variables {
    bucket_name     = "example-bucket"
    expiration_days = 0
  }

  expect_failures = [
    var.expiration_days,
  ]
}
