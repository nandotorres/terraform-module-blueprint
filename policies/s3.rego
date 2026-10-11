# terraform show -json
package main

import rego.v1

resource_changes := object.get(input, "resource_changes", [])

is_write(resource) if {
	some action in resource.change.actions
	action in {"create", "update"}
}

managed_writes(type) := [resource |
	some resource in resource_changes
	resource.mode == "managed"
	resource.type == type
	is_write(resource)
]

retained(type) := [resource |
	some resource in resource_changes
	resource.mode == "managed"
	resource.type == type
	not "delete" in resource.change.actions
]

deny contains msg if {
	count(managed_writes("aws_s3_bucket")) > count(retained("aws_s3_bucket_public_access_block"))
	msg := "every created or updated aws_s3_bucket needs an aws_s3_bucket_public_access_block in the same plan"
}

deny contains msg if {
	count(managed_writes("aws_s3_bucket")) > count(retained("aws_s3_bucket_server_side_encryption_configuration"))
	msg := "every created or updated aws_s3_bucket needs an aws_s3_bucket_server_side_encryption_configuration in the same plan"
}

deny contains msg if {
	count(managed_writes("aws_s3_bucket")) > count(retained("aws_s3_bucket_versioning"))
	msg := "every created or updated aws_s3_bucket needs an aws_s3_bucket_versioning in the same plan"
}

deny contains msg if {
	some resource in managed_writes("aws_s3_bucket_public_access_block")
	after := resource.change.after
	not public_access_closed(after)
	msg := sprintf("%s must set block_public_acls, block_public_policy, ignore_public_acls, and restrict_public_buckets to true", [resource.address])
}

deny contains msg if {
	some resource in managed_writes("aws_s3_bucket_server_side_encryption_configuration")
	not encryption_allowed(resource)
	msg := sprintf("%s must encrypt objects with AES256 or aws:kms", [resource.address])
}

deny contains msg if {
	some resource in managed_writes("aws_s3_bucket_versioning")
	not versioning_enabled(resource)
	msg := sprintf("%s must set versioning status to Enabled", [resource.address])
}

deny contains msg if {
	some resource in managed_writes("aws_s3_bucket")
	some key in {"Environment", "Owner", "ManagedBy"}
	not tag_present(resource, key)
	msg := sprintf("%s is missing required tag %s", [resource.address, key])
}

public_access_closed(after) if {
	after.block_public_acls == true
	after.block_public_policy == true
	after.ignore_public_acls == true
	after.restrict_public_buckets == true
}

encryption_allowed(resource) if {
	rule := resource.change.after.rule[0]
	algorithm := rule.apply_server_side_encryption_by_default[0].sse_algorithm
	algorithm in {"AES256", "aws:kms"}
}

versioning_enabled(resource) if {
	resource.change.after.versioning_configuration[0].status == "Enabled"
}

tag_present(resource, key) if {
	value := object.get(object.get(resource.change.after, "tags", {}), key, "")
	value != ""
}
