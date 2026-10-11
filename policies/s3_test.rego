package main

import rego.v1

test_allows_secure_bucket if {
	count(deny) == 0 with input as {"resource_changes": secure_resources}
}

test_denies_bucket_without_public_access_block if {
	resources := array.concat(
		array.slice(secure_resources, 0, 1),
		array.slice(secure_resources, 2, count(secure_resources)),
	)
	count(deny) > 0 with input as {"resource_changes": resources}
}

test_denies_open_public_access_block if {
	count(deny) > 0 with input as {"resource_changes": array.concat(
		[bucket, encryption, versioning],
		[object.union(public_access, {"change": {"actions": ["create"], "after": {
			"block_public_acls": false,
			"block_public_policy": true,
			"ignore_public_acls": true,
			"restrict_public_buckets": true,
		}}})],
	)}
}

test_denies_missing_owner_tag if {
	count(deny) > 0 with input as {"resource_changes": [bucket_missing_owner, public_access, encryption, versioning]}
}

secure_resources := [bucket, public_access, encryption, versioning]

bucket := {
	"address": "module.bucket.aws_s3_bucket.this",
	"mode": "managed",
	"type": "aws_s3_bucket",
	"change": {"actions": ["create"], "after": {"bucket": "example", "tags": {
		"Environment": "test",
		"Owner": "platform",
		"ManagedBy": "terraform",
		"Module": "s3_bucket",
	}}},
}

public_access := {
	"address": "module.bucket.aws_s3_bucket_public_access_block.this",
	"mode": "managed",
	"type": "aws_s3_bucket_public_access_block",
	"change": {"actions": ["create"], "after": {
		"block_public_acls": true,
		"block_public_policy": true,
		"ignore_public_acls": true,
		"restrict_public_buckets": true,
	}},
}

encryption := {
	"address": "module.bucket.aws_s3_bucket_server_side_encryption_configuration.this",
	"mode": "managed",
	"type": "aws_s3_bucket_server_side_encryption_configuration",
	"change": {"actions": ["create"], "after": {"rule": [{
		"apply_server_side_encryption_by_default": [{"sse_algorithm": "AES256"}],
	}]}},
}

bucket_missing_owner := {
	"address": "module.bucket.aws_s3_bucket.this",
	"mode": "managed",
	"type": "aws_s3_bucket",
	"change": {"actions": ["create"], "after": {"bucket": "example", "tags": {
		"Environment": "test",
		"ManagedBy": "terraform",
	}}},
}

versioning := {
	"address": "module.bucket.aws_s3_bucket_versioning.this",
	"mode": "managed",
	"type": "aws_s3_bucket_versioning",
	"change": {"actions": ["create"], "after": {"versioning_configuration": [{"status": "Enabled"}]}},
}
