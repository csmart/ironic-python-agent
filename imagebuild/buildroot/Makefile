.PHONY: default all dependencies build config fetch source toolchain legal clean distclean clean-images reset menuconfig busybox-menuconfig linux-menuconfig saveconfig busybox-saveconfig linux-saveconfig help

default: all

all: dependencies build

deps: dependencies

## Install required dependencies
dependencies:
	./install-deps.sh $(DEBUG)

## Build targets
build:
	./build-buildroot.sh --all $(DEBUG)

config:
	./build-buildroot.sh --config $(DEBUG)

fetch:
	./build-buildroot.sh --fetch $(DEBUG)

source:
	./build-buildroot.sh --source $(DEBUG)

toolchain:
	./build-buildroot.sh --toolchain $(DEBUG)

# Licensing
legal:
	./build-buildroot.sh --legal $(DEBUG)

## Clean targets
# Remove everything by default
# Buildroot "make clean"
clean:
	./clean-buildroot.sh --build $(DEBUG)

# Buildroot "make distclean"
# Delete all non-source files (including .config)
distclean:
	./clean-buildroot.sh --dist $(DEBUG)

# Remove only current images, leaving everything else in place
clean-images:
	./clean-buildroot.sh --images $(DEBUG)

# Clean everything, remove any customisations leaving only pristine Git repos
reset:
	./clean-buildroot.sh --reset $(DEBUG)

## Configuration helper targets
menuconfig:
	./customise-buildroot.sh --menuconfig $(DEBUG)

busybox-menuconfig:
	./customise-buildroot.sh --busybox-menuconfig $(DEBUG)

linux-menuconfig:
	./customise-buildroot.sh --linux-menuconfig $(DEBUG)

saveconfig:
	./customise-buildroot.sh --saveconfig $(DEBUG)

busybox-saveconfig:
	./customise-buildroot.sh --busybox-saveconfig $(DEBUG)

linux-saveconfig:
	./customise-buildroot.sh --linux-saveconfig $(DEBUG)

# How to use this Makefile
help:
	@echo 'Available targets:'
	@echo
	@echo 'Building'
	@echo '  build                 - Fetch source, configure and build (default target)'
	@echo '  config                - Load default configuration'
	@echo '  fetch                 - Git clone Buildroot repositories'
	@echo '  source                - Download all source code required'
	@echo '  toolchain             - Build only the Buildroot toolchain'
	@echo
	@echo 'Customising'
	@echo '  menuconfig            - Make changes to main Buildroot config'
	@echo '  busybox-menuconfig    - Make changes to Busybox config'
	@echo '  linux-menuconfig      - Make changes to Linux kernel config'
	@echo '  saveconfig            - Save main Buildroot config changes'
	@echo '  busybox-saveconfig    - Save Busybox config changes'
	@echo '  linux-saveconfig      - Save Linux kernel config changes'
	@echo
	@echo 'Cleaning'
	@echo '  clean                 - Delete files created by build, excludes config and src'
	@echo '  clean-images          - Deleting only built images'
	@echo '  distclean             - Deleting all non-source files, includes .config'
	@echo '  reset                 - Clean everything, remove changes, revert Git repos'
	@echo
	@echo 'Debugging'
	@echo '  DEBUG=debug <target>  - This will enable debug in shell scripts'

