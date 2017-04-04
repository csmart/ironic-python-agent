#!/bin/bash

## Customisation helper script for Buildroot IPA image
##
## Assumes we've already checked out Buildroot and have a config
##
## Variables and functions are in buildroot-lib.sh

# We want to know if things fail
grep -q debug <<< "${@}" && set -x # Early debug
set -o errexit
set -o pipefail
set -o nounset

## It's best to not build as root, but up to you
[[ "${EUID}" -eq 0 ]] && { echo -e "WARNING: Running as root is not recommended.
Continuing in 10 seconds, hit CTRL+C to cancel." ; sleep 10 ; }

# Load common variables and functions
# shellcheck disable=SC1090
source "$(dirname "$(readlink -f "${0}")")/buildroot-lib.sh"

# Local functions
usage(){
	cat << EOF
Usage: ${0} <options>

Options:
 -m, --menuconfig             Customise Buildroot
 -M, --saveconfig             Copy Buildroot config from output to Git repo
 -b, --busybox-menuconfig     Customise Busybox
 -B, --busybox-saveconfig     Copy Busybox config from output to Git repo
 -l, --linux-menuconfig       Customise Linux kernel
 -L, --linux-saveconfig       Copy Linux kernel config from output to Git repo

Debug options:
 --debug                      Enable debug output (set -x)
EOF
	exit 0
}

## We need at least one argument to know what to do
[[ -z "${@}" ]] && usage

## Work out what we want to do
CMD_LINE=$(getopt -o bBhmMlL --longoptions busybox-menuconfig,busybox-saveconfig,help,linux-menuconfig,linux-saveconfig,menuconfig,saveconfig -n "${0}" -- "${@}")
eval set -- "${CMD_LINE}"

while true ; do
	case "${1}" in
		-b|--busybox-menuconfig)
			JOBS_TO_DO+=" busybox-menuconfig"
			shift
			;;
		-B|--busybox-saveconfig)
			JOBS_TO_DO+=" busybox-saveconfig"
			shift
			;;
		--debug)
			set -x
			shift
			;;
		-h|--help)
			usage
			;;
		-l|--linux-menuconfig)
			JOBS_TO_DO+=" linux-menuconfig"
			shift
			;;
		-L|--linux-saveconfig)
			JOBS_TO_DO+=" linux-saveconfig"
			shift
			;;
		-m|--menuconfig)
			JOBS_TO_DO+=" menuconfig"
			shift
			;;
		-M|--saveconfig)
			JOBS_TO_DO+=" saveconfig"
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

# Do all the jobs now
for job in ${JOBS_TO_DO}; do
	${job}
done
