SRC_ROOT := $(realpath .)
TOOLS_MOD_DIR := $(SRC_ROOT)/tools
TOOLS_MOD_REGEX := "\s+_\s+\".*\""
TOOLS_PKG_NAMES := $(shell grep -E $(TOOLS_MOD_REGEX) < $(TOOLS_MOD_DIR)/tools.go | tr -d " _\"")
TOOLS_BIN_DIR := $(SRC_ROOT)/.tools
TOOLS_BIN_NAMES := $(addprefix $(TOOLS_BIN_DIR)/, $(notdir $(TOOLS_PKG_NAMES)))

LICENSE := $(TOOLS_BIN_DIR)/addlicense
TFLINT := $(TOOLS_BIN_DIR)/tflint
TFDOCS := $(TOOLS_BIN_DIR)/terraform-docs

SHELL := /bin/bash

GO ?= $(shell command -v go)

$(TOOLS_BIN_DIR):
	mkdir -p $@

$(TOOLS_BIN_NAMES): $(TOOLS_BIN_DIR) $(TOOLS_MOD_DIR)/go.mod
	cd $(TOOLS_MOD_DIR) && GOOS="" GOARCH="" $(GO) build -o $@ -trimpath $(filter %/$(notdir $@),$(TOOLS_PKG_NAMES))

.PHONY: install-tools
install-tools: $(TOOLS_BIN_NAMES)

.PHONY: add-license
add-license: $(LICENSE)
	@echo "Add elastic license to files."
	@$(LICENSE) -f license_header.txt .

.PHONY: check-license
check-license: $(LICENSE)
	@echo "Check files have the elastic license."
	@$(LICENSE) -check . || (echo "Elastic license missing. Run 'make add-license'." && exit 1)

.PHONY: terraform-fmt
terraform-fmt:
	@echo "Formatting terraform files."
	@cd modules; terraform fmt -recursive

.PHONY: check-terraform-fmt
check-terraform-fmt:
	@echo "Check terraform formatting."
	@cd modules; terraform fmt -recursive -check || (echo "Terraform formatting not as expected. Run 'make terraform-fmt'." && exit 1)

.PHONY: tflint
tflint: $(TFLINT)
	@echo "Running TFLint."
	@$(TFLINT) --init --config $(SRC_ROOT)/.tflint.hcl; $(TFLINT) --recursive --config $(SRC_ROOT)/.tflint.hcl

.PHONY: tfdocs
tfdocs: $(TFDOCS)
	@echo "Running terraform-docs."
	@$(TFDOCS) --config $(SRC_ROOT)/.terraform-docs.yaml .

.PHONY: check-tfdocs
check-tfdocs: $(TFDOCS)
	@echo "Check if terraform docs are up to date."
	@$(TFDOCS) --config $(SRC_ROOT)/.terraform-docs.yaml --output-check . || (echo "README files are not up to date. Run 'make tfdocs'." && exit 1)

.PHONY: contribute
contribute:
	@echo "Run requirements to make sure project is in expected state."
	@$(MAKE) --no-print-directory terraform-fmt
	@$(MAKE) --no-print-directory tfdocs
	@$(MAKE) --no-print-directory add-license

.PHONY: checks
checks:
	@echo "Check that the project is in the expected state"
	@$(MAKE) --no-print-directory check-terraform-fmt || exit 1
	@$(MAKE) --no-print-directory tflint || exit 1
	@$(MAKE) --no-print-directory check-tfdocs || exit 1
	@$(MAKE) --no-print-directory check-license || exit 1