.PHONY: docs fmt lint lint-fix check

docs:
	rm -f .terraform.lock.hcl
	terraform-docs .
	prettier --write README.md

fmt: docs
	terraform fmt -recursive

lint:
	tflint --init
	tflint --format compact

lint-fix:
	tflint --init
	tflint --fix

check: lint
	rm -f .terraform.lock.hcl
	terraform-docs --output-check .
	prettier --check README.md
	terraform fmt -check -recursive
