SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

.PHONY: help check init fmt validate lint security docs docs-check unit policy-unit policy-plan policy up down e2e test hooks simulate

help:
	@printf '%s\n' \
	  'check        format, validate, lint, trivy, docs, unit tests, and policy unit tests' \
	  'fmt          terraform fmt -check' \
	  'validate     terraform validate' \
	  'lint         tflint' \
	  'security     trivy config' \
	  'docs         refresh modules/s3_bucket/README.md' \
	  'docs-check   fail if the module README is stale' \
	  'unit         terraform test' \
	  'policy-unit  conftest verify' \
	  'policy-plan  conftest against a LocalStack plan' \
	  'policy       start LocalStack and run policy-plan' \
	  'up           start LocalStack' \
	  'down         stop LocalStack' \
	  'e2e          apply the example with Terratest' \
	  'test         check, policy, and e2e' \
	  'hooks        install the prek pre-commit hook' \
	  'simulate     fail fmt, tflint, trivy, unit tests, and policy on purpose'

check: fmt validate lint security docs-check unit policy-unit

init:
	terraform -chdir=modules/s3_bucket init -backend=false -input=false
	terraform -chdir=examples/complete init -backend=false -input=false

fmt:
	terraform fmt -check -recursive -diff

validate: init
	terraform -chdir=modules/s3_bucket validate
	terraform -chdir=examples/complete validate

lint:
	tflint --init
	tflint --chdir=modules/s3_bucket --config=$(CURDIR)/.tflint.hcl
	tflint --chdir=examples/complete --config=$(CURDIR)/.tflint.hcl

security:
	trivy config --config trivy.yaml --exit-code 1 --severity HIGH,CRITICAL .

docs:
	terraform-docs --config $(CURDIR)/.terraform-docs.yml $(CURDIR)/modules/s3_bucket

docs-check:
	terraform-docs --config $(CURDIR)/.terraform-docs.yml --output-check $(CURDIR)/modules/s3_bucket

unit: init
	terraform -chdir=modules/s3_bucket test

policy-unit:
	conftest verify --policy $(CURDIR)/policies

policy-plan: init
	AWS_ACCESS_KEY_ID=test \
	AWS_SECRET_ACCESS_KEY=test \
	AWS_DEFAULT_REGION=us-east-1 \
	AWS_EC2_METADATA_DISABLED=true \
	terraform -chdir=examples/complete plan -input=false -lock=false -out=$(CURDIR)/tfplan
	terraform -chdir=examples/complete show -json $(CURDIR)/tfplan > $(CURDIR)/tfplan.json
	conftest test $(CURDIR)/tfplan.json --policy $(CURDIR)/policies
	rm -f $(CURDIR)/tfplan $(CURDIR)/tfplan.json

policy: up policy-plan

up:
	docker compose up -d --wait

down:
	docker compose down --remove-orphans

e2e: up
	cd tests/e2e && go test -count=1 -timeout 20m -v ./...

test: check policy e2e

hooks:
	prek install

simulate:
	bash $(CURDIR)/scripts/simulate.sh
