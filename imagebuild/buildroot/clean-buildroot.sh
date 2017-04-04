#!/bin/bash

## Clean script for Buildroot IPA image
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
 -b, --build    Delete files created by build, excluding .config and src
 -d, --dist     Delete all non-source files, including .config
 -i, --images   Delete only built images, excluding everything else
 -r, --reset    Delete everything and remove uncommitted Git changes

Debug options:
 --debug        Enable debug output (set -x)

EOF
	exit 0
}

## We need at least one argument to know what to do
[[ -z "${@}" ]] && usage

## Work out what we want to do
CMD_LINE=$(getopt -o cdhir --longoptions build,dist,help,images,reset -n "${0}" -- "${@}")
eval set -- "${CMD_LINE}"

while true ; do
	case "${1}" in
		-b|--build)
			JOBS_TO_DO+=" clean-build"
			shift
			;;
		-d|--dist)
			JOBS_TO_DO+=" clean-dist"
			shift
			;;
		-h|--help)
			usage
			;;
		-i|--images)
			JOBS_TO_DO+=" clean-images"
			shift
			;;
		--debug)
			set -x
			shift
			;;
		-r|--reset)
			JOBS_TO_DO+=" clean-reset"
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
