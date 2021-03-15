.DEFAULT_GOAL := help

# Job parameter: src directory.
CURRENT_DIR := $(shell pwd)

.PHONY: help build test push format lint install.dependencies version.get version.set version.bump

#help:	@ List available tasks on this project
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

#install.dependencies: @ install dependencies.
install.dependencies:
	@exec >&2; \
	echo "> Installing dependencies."; \
	python3 -m venv venv; \
	. venv/bin/activate; \
	venv/bin/python3 -m pip -q install --upgrade pip; \
	venv/bin/pip -q install bump2version==1.0.1

#build: @ Builds the package.
build:
	@exec >&2; \
	echo "> Building."; \
	echo "NOOP."

#test: @ Tests the package.
test:
	@exec >&2; \
	echo "> Testing."; \
	export AWS_DEFAULT_REGION="eu-west-3"; \
	terraform init; \
	terraform validate

#test: @ Push the package.
push:
	@exec >&2; \
	echo "> Pushing."; \
	echo "NOOP."

#format: @ Format code
format:
	@exec >&2; \
	echo "> Formatting."; \
	terraform fmt; \
	make -C lambda_function format

#lint: @ Lint package
lint:
	@exec >&2; \
	echo "> Linting."; \
	terraform fmt -check; \
	make -C lambda_function lint

#version.get: @ Gets the version value.
version.get: install.dependencies
	@venv/bin/bump2version --allow-dirty --dry-run --list patch | grep current_version | sed "s|^.*=||"

#version.get-released: @ Gets the released version value.
version.get-released: version.get

#version.set: @ Sets the version value.
version.set: install.dependencies
	@exec >&2; \
	echo "> Setting version $(VERSION)"; \
	venv/bin/bump2version --allow-dirty --new-version $(VERSION) patch

#version.bump: @ Bump the version value.
version.bump: install.dependencies
	@exec >&2; \
	echo "> Bumping version."; \
	venv/bin/bump2version --allow-dirty patch
