SHELL := /bin/bash

REPO_ROOT := $(abspath ..)
LOADER_DIR := $(REPO_ROOT)/loader
POSTEX_DIR := $(REPO_ROOT)/postex-loader
BUILD_DIR := build

.PHONY: all objects clean help

help:
	@echo "Targets:"
	@echo "  objects   Build all .o/.bin objects under loader/ and postex-loader/"
	@echo "  package   Package crystal-loader.x64.dll + extension.json as a tarball"
	@echo "            (requires crystal-loader.x64.dll to be present, see step 6)"
	@echo "  clean     Remove build artefacts"
	@echo ""
	@echo "Scripts:"
	@echo "  ./generate.sh <input.dll> [args-file] [output.bin]"
	@echo "  ./generate-implant.sh <profile-name> [output.bin]"
	@echo "  ./pack-extension.sh [output.tar.gz]"
	@echo ""
	@echo "Required env: CRYSTAL_PALACE_HOME (dir with crystalpalace.jar)"

objects:
	$(MAKE) -C $(LOADER_DIR) all
	$(MAKE) -C $(POSTEX_DIR) all

package:
	@./pack-extension.sh $(BUILD_DIR)/crystal-loader-0.1.0.tar.gz

clean:
	$(MAKE) -C $(LOADER_DIR) clean
	$(MAKE) -C $(POSTEX_DIR) clean
	rm -rf $(BUILD_DIR)
