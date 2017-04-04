#!/bin/bash

## Build script for Buildroot IPA image
## Defaults to building everything (else pass an option)
##
## Assumes we've already run install-deps.sh
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
 -b, --build        Full build; fetch, configure and build
 -c, --config       Load default config, if not already
 -f, --fetch        Clone the Buildroot Git repositories, if not already
 -s, --source       Download all the source files required for build
 -t, --toolchain    Build only the toolchain

Debug options:
 --debug            Enable debug output (set -x)

EOF
	exit 0
}

## We need at least one argument to know what to do
[[ -z "${@}" ]] && usage

## Work out what we want to do
CMD_LINE=$(getopt -o acfhlst --longoptions all,config,debug,fetch,git-branch:,git-url:,help,legal,source,toolchain -n "${0}" -- "${@}")
eval set -- "${CMD_LINE}"

while true ; do
	case "${1}" in
		-a|--all)
			JOBS_TO_DO+=" build-all"
			shift
			;;
		-c|--config)
			JOBS_TO_DO+=" build-config"
			shift
			;;
		--debug)
			set -x
			shift
			;;
		-f|--fetch)
			JOBS_TO_DO+=" build-fetch"
			shift
			;;
		--git-branch)
			export GIT_BRANCH="${2}"
			shift 2
			;;
		--git-url)
			export GIT_REPO="${2}"
			shift 2
			;;
		-h|--help)
			usage
			;;
		-l|--legal)
			JOBS_TO_DO+=" build-legal"
			shift
			;;
		-s|--source)
			JOBS_TO_DO+=" build-source"
			shift
			;;
		-t|--toolchain)
			JOBS_TO_DO+=" build-toolchain"
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

# If we're building all, ignore other commands as they get run anyway
[[ "${JOBS_TO_DO}" =~ build-all ]] && JOBS_TO_DO="build-all"

# Do all the jobs now
for job in ${JOBS_TO_DO}; do
	${job}
done
