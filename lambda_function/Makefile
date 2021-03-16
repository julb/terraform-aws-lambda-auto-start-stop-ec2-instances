.DEFAULT_GOAL := help

# Job parameter: src directory.
CURRENT_DIR := $(shell pwd)
SRC_DIR := $(CURRENT_DIR)/src
DIST_DIR := $(CURRENT_DIR)/dist

.PHONY: help build test push format lint install.dependencies

#help:	@ List available tasks on this project
help:
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#'  | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

#install.dependencies: @ install dependencies.
install.dependencies:
	@exec >&2; \
	echo "> Installing dependencies."; \
	rm -rf venv-lambda; \
	python3 -m venv venv-lambda; \
	. venv-lambda/bin/activate; \
	venv-lambda/bin/python3 -m pip -q install --upgrade pip; \
	venv-lambda/bin/pip -q install -r $(CURRENT_DIR)/requirements-dev.txt -r $(CURRENT_DIR)/requirements.txt

#build: @ Builds the package.
build:
	@exec >&2; \
	echo "> Building."; \
	rm -rf venv-lambda; \
	python3 -m venv venv-lambda; \
	. venv-lambda/bin/activate; \
	venv-lambda/bin/python3 -m pip -q install --upgrade pip; \
	rm -rf $(DIST_DIR); \
	mkdir -p $(DIST_DIR); \
	cp -R $(SRC_DIR)/* $(DIST_DIR); \
	venv-lambda/bin/pip3 install -q -r $(CURRENT_DIR)/requirements.txt --target $(DIST_DIR)/dist-packages/

#test: @ Tests the package.
test:
	@exec >&2; \
	echo "> Testing."; \
	echo "NOOP."

#test: @ Push the package.
push:
	@exec >&2; \
	echo "> Pushing."; \
	echo "NOOP."

#format: @ Format code
format: install.dependencies
	@exec >&2; \
	echo "> Formatting."; \
	venv-lambda/bin/autopep8 -ir $(SRC_DIR)

#lint: @ Lint package
lint: install.dependencies
	@exec >&2; \
	echo "> Linting."; \
	echo "Running pycodestyle."; \
	venv-lambda/bin/pycodestyle $(SRC_DIR); \
	echo "Running pylint."; \
	venv-lambda/bin/pylint $(SRC_DIR)