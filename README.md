# Terraform module blueprint

Implementation reference for a Terraform module used as a building block in an organization IaC stack. This one is an S3 bucket on [terraform-aws-modules/s3-bucket/aws](https://registry.terraform.io/modules/terraform-aws-modules/s3-bucket/aws/5.16.2) 5.16.2.

It implements:

- Versioning, SSE-S3, a public access block, `BucketOwnerEnforced`, and a bucket policy that denies plain HTTP
- Required `Environment` and `Owner` tags
- fmt, validate, TFLint, Trivy, docs, `terraform test`, and Conftest on the plan
- An apply test with Terratest and LocalStack

## Checks

| Check | Where |
| --- | --- |
| fmt, validate, terraform test | `modules/s3_bucket` |
| TFLint | `.tflint.hcl` |
| Trivy | `trivy.yaml` |
| terraform-docs | `.terraform-docs.yml` |
| Conftest on the plan | `policies/` |
| Terratest on LocalStack | `tests/e2e`, `examples/complete` |
| prek | `.pre-commit-config.yaml` |

## Run

Install [Nix](https://nixos.org/download/). `make test` needs Docker running (Docker Desktop or Colima).

```sh
nix develop
make test
```

`make check` does not start Docker. `make simulate` sends a broken file through fmt, tflint, trivy, `terraform test`, and conftest, and expects each one to fail. If Nix says flakes are experimental, add `--extra-experimental-features 'nix-command flakes'`.

## Tools

- HashiCorp — `terraform fmt`, `validate`, `test`
- TFLint — recommended preset and the AWS ruleset
- Trivy
- Conftest, on `terraform show -json`
- Terratest — Yevgeniy Brikman, *Terraform: Up & Running*
- pre-commit-terraform — Anton Babenko
- LocalStack — S3 and STS for the apply test
- Kief Morris, *Infrastructure as Code*

## License

[MIT](LICENSE)
