#!/bin/bash
set -eu -o pipefail

declare -r GREADLINK=$(which greadlink)
declare -r READLINK=${GREADLINK:-"$(which readlink)"}

declare -r BASE_DIR="$(dirname $(${READLINK} -f $0))"
declare -r BASE_DIR_DOCKER="/debian-docker"

declare -r DOCKER_SCRIPT="${BASE_DIR_DOCKER}/create-debian-image.sh"
declare -r DEBOOTSTAP_DIR_NAME="debootstrap"
declare -r DEBOOTSTAP_DIR_DOCKER="${BASE_DIR_DOCKER}/${DEBOOTSTAP_DIR_NAME}"

mkdir "${BASE_DIR}/${DEBOOTSTAP_DIR_NAME}"

## debootstrab in a docker container
docker run --rm -v "${BASE_DIR}":"${BASE_DIR_DOCKER}" debian:stretch-slim "${DOCKER_SCRIPT}" "${DEBOOTSTAP_DIR_DOCKER}"

## create docker image
tar -C "${TMPDIR}" -c . | docker import - debootstrap-stretch
