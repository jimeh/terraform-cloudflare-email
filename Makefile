.PHONY: docs fmt check

docs:
	terraform-docs .
	prettier --write README.md

fmt: docs
	terraform fmt -recursive

check:
	terraform-docs --output-check .
	prettier --check README.md
	terraform fmt -check -recursive
