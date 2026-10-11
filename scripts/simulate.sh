#!/usr/bin/env bash
# Fail fmt, tflint, trivy, terraform test, and conftest on purpose.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"; rm -f "$root/modules/s3_bucket/tests/zz_simulate.tftest.hcl"' EXIT

section() {
  printf '\n== %s ==\n' "$1"
}

expect_fail() {
  local name="$1"
  shift
  set +e
  "$@"
  local status=$?
  set -e
  if [[ "$status" -eq 0 ]]; then
    printf '\n%s did not fail.\n' "$name" >&2
    exit 1
  fi
  printf '\n%s rejected it (exit %s).\n' "$name" "$status"
}

section "fmt"
mkdir -p "$work/fmt"
cat > "$work/fmt/main.tf" <<'EOF'
resource "aws_s3_bucket" "this" {
bucket = "insecure-example"
}
EOF
expect_fail "terraform fmt" terraform fmt -check -diff -recursive "$work/fmt"

section "tflint and trivy"
mkdir -p "$work/insecure"
cat > "$work/insecure/main.tf" <<'EOF'
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.42.0"
    }
  }
}

resource "aws_s3_bucket" "public" {
  bucket = "Insecure_Example"
}

resource "aws_s3_bucket_public_access_block" "public" {
  bucket                  = aws_s3_bucket.public.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
EOF
expect_fail "tflint" tflint --chdir="$work/insecure" --config="$root/.tflint.hcl" --minimum-failure-severity=warning
expect_fail "trivy" trivy config --exit-code 1 --severity HIGH,CRITICAL --quiet "$work/insecure"

section "terraform test"
cat > "$root/modules/s3_bucket/tests/zz_simulate.tftest.hcl" <<'EOF'
mock_provider "aws" {
  override_during = plan

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

run "bad_bucket_name_is_rejected" {
  command = plan

  variables {
    bucket_name = "NO"
    tags = {
      Environment = "test"
      Owner       = "platform"
    }
  }
}
EOF
expect_fail "terraform test" terraform -chdir="$root/modules/s3_bucket" test -filter=tests/zz_simulate.tftest.hcl
rm -f "$root/modules/s3_bucket/tests/zz_simulate.tftest.hcl"

section "conftest"
cat > "$work/violating.json" <<'EOF'
{
  "resource_changes": [
    {
      "address": "module.bucket.aws_s3_bucket.this",
      "mode": "managed",
      "type": "aws_s3_bucket",
      "change": {
        "actions": ["create"],
        "after": {
          "bucket": "insecure-example",
          "tags": {
            "Environment": "test",
            "ManagedBy": "terraform"
          }
        }
      }
    }
  ]
}
EOF
expect_fail "conftest" conftest test "$work/violating.json" --policy "$root/policies"
