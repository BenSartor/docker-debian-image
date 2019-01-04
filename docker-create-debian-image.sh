#!/bin/bash
set -eu -o pipefail

declare -r DEBOOTSTAP_DIR="debootstrap"
declare -r DEBOOTSTAP_DIR_DOCKER="/debootstrap"

mkdir "${DEBOOTSTAP_DIR}"

## debootstrab in a docker container
docker run --rm -v $(greadlink -f "${DEBOOTSTAP_DIR}"):"${DEBOOTSTAP_DIR_DOCKER}" debian:stretch-slim bash -c "apt update ; apt dist-upgrade -y ; apt install -y debootstrap fakechroot fakeroot ; fakechroot fakeroot debootstrap --variant=minbase stretch \"${DEBOOTSTAP_DIR_DOCKER}\" http://deb.debian.org/debian"
