#!/bin/env bash

## This file is sourced by IPA Buildroot scripts
## It's a central place to store variables and functions

## Local variables
GIT_REPO="${GIT_REPO:-https://github.com/csmart/ipa-buildroot}"
GIT_BRANCH="${GIT_BRANCH:-master}"
DIR="$(dirname "$(readlink -f "${0}")")"
BR2_IPA_REPO="${DIR}/build"
BR2_UPSTREAM="${BR2_IPA_REPO}/buildroot"
BR2_OUTPUT_DIR="${BR2_IPA_REPO}/output"
BR2_DEFCONFIG="${BR2_DEFCONFIG:-openstack_ipa_defconfig}"
JOBS_TO_DO="${JOBS_TO_DO:-}"

## Buildroot variables
export BR2_EXTERNAL="${BR2_IPA_REPO}/buildroot-ipa"

## Build dependencies variables
# shellcheck disable=SC2034
COMMON_PACKAGES="bash bc bzr git rsync texinfo wget unzip"
# shellcheck disable=SC2034
APT_PACKAGES="${COMMON_PACKAGES} build-essential gcc-multilib libncurses5-dev libc6-i386"
# shellcheck disable=SC2034
YUM_PACKAGES="${COMMON_PACKAGES} binutils bison bzip2 cmake cpio \
	flex gcc gcc-c++ glibc-devel glibc-devel.i686 glibc-headers.i686 gzip \
	make ncurses-devel patch perl perl-ExtUtils-MakeMaker perl-Thread-Queue \
	python redhat-lsb.i686 rsync sed tar unzip wget which"

## Functions
print-out(){
	MSG_TYPE="${1^^}"
	if [[ "${MSG_TYPE}" == "ERROR" ]]; then
		if [[ "${FUNCNAME[1]}" =~ check ]]; then
			MSG_TYPE+=": ${FUNCNAME[2]}()"
		else
			MSG_TYPE+=": ${FUNCNAME[1]}()"
		fi
	fi
	echo -en "\n${MSG_TYPE}: "
	echo -e "${2}\n"
}

check-output(){
	OPTIONAL_DIR="${1:-}"
	if [[ -d "${BR2_OUTPUT_DIR}/${OPTIONAL_DIR}" ]]; then
		return 0
	else
		print-out error "No output/${OPTIONAL_DIR} dir, do you need to fetch first?"
		return 1
	fi
}

check-config(){
	if [[ -e "${BR2_OUTPUT_DIR}/.config" ]]; then
		return 0
	else
		print-out error "No config found, do you need to run config first?"
		return 1
	fi
}

# Building
build-config(){
	check-output || return 1
	if check-config &>/dev/null; then
		print-out warning "Skipping config, found existing at:\n${BR2_OUTPUT_DIR}/.config"
		return
	fi

	print-out info "Loading IPA Buildroot configuration..."
	pushd "${BR2_OUTPUT_DIR}"
	make O="${BR2_OUTPUT_DIR}" -C "${BR2_UPSTREAM}" "${BR2_DEFCONFIG}"
	# Use HEAD of this checked out ironic-python-agent rather than upstream
	# shellcheck disable=SC2016
	sed -i 's|^OPENSTACK_IPA_GIT_URL=.*|OPENSTACK_IPA_GIT_URL="$(BR2_EXTERNAL_IPA_PATH)/../../../../"|g' .config
	sed -i 's|^OPENSTACK_IPA_RELEASE=.*|OPENSTACK_IPA_RELEASE=""|g' .config

	popd
	print-out success "Loaded configuration, ${BR2_DEFCONFIG}"
}

build-fetch(){
	if [[ -d "${BR2_IPA_REPO}/.git" ]]; then
		print-out warning "Skipping fetch, already exists at:\n${BR2_IPA_REPO}"
		return
	fi

	# Get the IPA and upstream Buildroot repositories
	print-out info "Cloning Buildroot recursively from ${GIT_REPO}..."
	git clone -b "${GIT_BRANCH}" --recursive "${GIT_REPO}" "${BR2_IPA_REPO}"
	print-out success "Buildroot cloned to ${BR2_IPA_REPO}"
}

build-legal(){
	check-config || return 1

	print-out info "Generating legal notices..."
	pushd "${BR2_OUTPUT_DIR}"
	make legal-info
	popd
	print-out success "Generated legal notices at:\n${BR2_OUTPUT_DIR}/legal-info/"
}

build-source(){
	check-config || return 1

	print-out info "Gathering all source for Buildroot packages..."
	pushd "${BR2_OUTPUT_DIR}"
	make source
	popd
	print-out success "Gathered all source for Buildroot packages"
}

build-toolchain(){
	check-config || return 1

	print-out info "Building toolchain for Buildroot..."
	pushd "${BR2_OUTPUT_DIR}"
	make toolchain
	popd
	print-out success "Build toolchain for Buildroot"
}

# Full build, fetches git repos, loads default config and builds
build-all(){
	build-fetch
	build-config
	print-out info "Building and creating IPA Buildroot image..."
	pushd "${BR2_OUTPUT_DIR}"
	make
	popd
	print-out success "Built IPA Buildroot images:\n${BR2_OUTPUT_DIR}/images/"
}

# Cleaning
clean-dist(){
	check-output || return

	print-out info "Deleting all non-source files (including .config)"
	pushd "${BR2_OUTPUT_DIR}"
	make distclean
	popd
	print-out success "Deleted all non-source files (including .config)"
}

clean-images(){
	check-output images || return

	print-out info "Deleting images."
	find "${BR2_OUTPUT_DIR}"/images/ -type f -exec rm -v {} \;
	print-out success "Deleted images."
}

clean-reset(){
	check-output || return

	pushd "${BR2_OUTPUT_DIR}"
	git clean -dfx
	git reset --hard
	popd
}

clean-build(){
	check-config || return

	print-out info "Deleting all files created by build (keeping .config and sources)"
	pushd "${BR2_OUTPUT_DIR}"
	make clean
	popd
	print-out success "Deleted all files created by build (kept .config and sources)"
}

# Customisation
menuconfig(){
	check-config || return

	print-out info "Making changes to main Buildroot config in output dir"
	pushd "${BR2_OUTPUT_DIR}"
	make menuconfig
	popd
	print-out success "Made changes to main Buildroot config in output dir"
}

busybox-menuconfig(){
	check-config || return

	print-out info "Making changes to Busybox config in output dir"
	pushd "${BR2_OUTPUT_DIR}"
	make busybox-menuconfig
	popd
	print-out success "Made changes to main Busybox config in output dir"
}

linux-menuconfig(){
	check-config || return

	print-out info "Making changes to Linux kernel config in output dir"
	pushd "${BR2_OUTPUT_DIR}"
	make linux-menuconfig
	popd
	print-out success "Made changes to main Linux kernel config in output dir"
}

saveconfig(){
	check-config || return

	print-out info "Saving main Buildroot config into Git repo"
	pushd "${BR2_OUTPUT_DIR}"
	make savedefconfig
	popd
	pushd "${BR2_IPA_REPO}"
	git status
	popd
	print-out success "Saved main Buildroot config into Git repo at:\n${BR2_IPA_REPO}"
}

busybox-saveconfig(){
	check-output || return

	print-out info "Saving Busybox config into Git repo"
	pushd "${BR2_OUTPUT_DIR}"
	make busybox-update-config
	popd
	pushd "${BR2_IPA_REPO}"
	git status
	popd
	print-out success "Saved Busybox config into Git repo at:\n${BR2_IPA_REPO}"
}

linux-saveconfig(){
	check-config || return

	print-out info "Saving Linux kernel config into Git repo"
	pushd "${BR2_OUTPUT_DIR}"
	make linux-savedefconfig
	make linux-update-defconfig
	popd
	pushd "${BR2_IPA_REPO}"
	git status
	popd
	print-out success "Saved Linux kernel config into Git repo at:\n${BR2_IPA_REPO}"
}

