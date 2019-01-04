#!/bin/bash
set -eu -o pipefail

declare -r GREADLINK=$(which greadlink)
declare -r READLINK=${GREADLINK:-"$(which readlink)"}

declare -r BASE_DIR="$(dirname $(${READLINK} -f $0))"
declare -r BASE_DIR_DOCKER="/debian-docker"

declare -r DOCKER_SCRIPT="${BASE_DIR_DOCKER}/create-debian-image.sh"
declare -r DEBOOTSTAP_DIR_NAME="debootstrap"
declare -r DEBOOTSTAP_DIR="${BASE_DIR}/${DEBOOTSTAP_DIR_NAME}"

mkdir "${DEBOOTSTAP_DIR}"

echo "debootstrab in a docker container"
docker run --privileged --cap-add=SYS_ADMIN --cap-add MKNOD --security-opt apparmor:unconfined --rm -v "${BASE_DIR}":"${BASE_DIR_DOCKER}" debian:stretch-slim "${DOCKER_SCRIPT}" "${BASE_DIR_DOCKER}" "${DEBOOTSTAP_DIR_NAME}"

echo "create docker image"
tar -C "${DEBOOTSTAP_DIR}" -c . | docker import - debootstrap-stretch

rm -rf "${DEBOOTSTAP_DIR}"

echo "done"
