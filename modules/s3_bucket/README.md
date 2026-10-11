# s3_bucket

S3 bucket building block for an organization stack. Uses [terraform-aws-modules/s3-bucket/aws](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/5.16.2) 5.16.2. Versioning, SSE-S3, public access block, `BucketOwnerEnforced`, and a deny-HTTP policy are set here.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.42.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_bucket"></a> [bucket](#module\_bucket) | terraform-aws-modules/s3-bucket/aws | 5.16.2 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Globally unique bucket name. Lowercase letters, numbers, dots, and hyphens, 3-63 characters, starting and ending with a letter or number. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the bucket. Environment and Owner are required and must be non-empty. The module sets ManagedBy and Module itself. | `map(string)` | n/a | yes |
| <a name="input_expiration_days"></a> [expiration\_days](#input\_expiration\_days) | Expire current object versions after this many days. Null omits the lifecycle configuration. | `number` | `null` | no |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Delete objects when destroying the bucket. | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the bucket. |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | Name of the bucket. |
| <a name="output_bucket_regional_domain_name"></a> [bucket\_regional\_domain\_name](#output\_bucket\_regional\_domain\_name) | Regional domain name of the bucket. |
| <a name="output_lifecycle_rules"></a> [lifecycle\_rules](#output\_lifecycle\_rules) | Lifecycle rules applied to the bucket. Null when expiration\_days is null. |
| <a name="output_tags"></a> [tags](#output\_tags) | Tags applied to the bucket, including ManagedBy and Module. |
| <a name="output_versioning_status"></a> [versioning\_status](#output\_versioning\_status) | Versioning status of the bucket. Always Enabled. |
<!-- END_TF_DOCS -->
