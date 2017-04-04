#!/bin/bash

## Installs required dependencies to build IPA buildroot image
## Currently only Fedora/CentOS and Debian/Ubuntu supported

# We want to know if things fail
grep -q debug <<< "${@}" && set -x # Early debug
set -o errexit
set -o pipefail
set -o nounset

# Load common variables and functions
# shellcheck disable=SC1090
source "$(dirname "$(readlink -f "${0}")")/buildroot-lib.sh"

# Local functions
usage(){
	cat << EOF
Usage: ${0}

This will install the dependencies required to build the IPA
Buildroot images.

List of dependencies is located in buildroot-lib.sh

Supported package managers are apt and dnf/yum.

Options:
 -h, --help         This help

Debug options:
 --debug            Enable debug output (set -x)

EOF
	exit 0
}

## Work out what we want to do
CMD_LINE=$(getopt -o h --longoptions debug,help -n "${0}" -- "${@}")
eval set -- "${CMD_LINE}"

while true ; do
	case "${1}" in
		--debug)
			set -x
			shift
			;;
		-h|--help)
			usage
			shift
			;;
		--)
			shift
			break
			;;
		*)
			usage
			;;
	esac
done

print-out info "Installing dependencies..."

# Assume we don't need to install, until we find missing packages
# This saves a sudo prompt every time we run a build
# (Buildroot does not build as root)
INSTALL=false

if [[ "$(type apt-get 2>/dev/null)" ]] ; then
	# Only install packages if any are missing
	for pkg in ${APT_PACKAGES}; do
		dpkg -l "${pkg}" |grep ^ii &>/dev/null || { INSTALL=true ; break ; }
	done
	if ${INSTALL} ; then
		sudo apt-get update
		# shellcheck disable=SC2086
		sudo apt-get install -y ${APT_PACKAGES}
	else
		print-out info "Dependencies already installed"
	fi
elif [[ "$(type dnf 2>/dev/null)" || "$(type yum 2>/dev/null)" ]] ; then
	PKG_TOOL="yum"
	type dnf &>/dev/null && PKG_TOOL="dnf"
	# Only install packages if any are missing
	for pkg in ${YUM_PACKAGES}; do
		rpm -q "${pkg}" &>/dev/null || { INSTALL=true ; break ; }
	done
	if ${INSTALL} ; then
		# shellcheck disable=SC2086
		sudo "${PKG_TOOL}" install -y ${YUM_PACKAGES}
	else
		print-out info "Dependencies already installed"
	fi
else
	echo -e "No supported package manager installed on system.\nSupported: apt, dnf, yum"
	exit 1
fi
