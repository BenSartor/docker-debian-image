#!/bin/bash
set -eu -o pipefail

declare -r GREADLINK=$(which greadlink)
declare -r READLINK=${GREADLINK:-"$(which readlink)"}

declare -r BASE_DIR="$(dirname $(${READLINK} -f $0))"
declare -r BASE_DIR_DOCKER="/debian-docker"

declare -r DOCKER_SCRIPT="${BASE_DIR_DOCKER}/create-debian-image.sh"
declare -r DEBOOTSTAP_DIR_NAME="debootstrap"
declare -r DEBOOTSTAP_DIR="${BASE_DIR}/${DEBOOTSTAP_DIR_NAME}"
declare -r DEBOOTSTAP_DIR_DOCKER="${BASE_DIR_DOCKER}/${DEBOOTSTAP_DIR_NAME}"

if [ -e "${DEBOOTSTAP_DIR}" ] ; then
    echo "error directory already exists: ${DEBOOTSTAP_DIR}"
    exit 1
fi

echo "debootstrab in a docker container"
docker run -it --privileged --cap-add=SYS_ADMIN --cap-add MKNOD --security-opt apparmor:unconfined --rm -v "${BASE_DIR}":"${BASE_DIR_DOCKER}" debian:stretch-slim bash -c "\"${DOCKER_SCRIPT}\" \"${DEBOOTSTAP_DIR_NAME}\" ; mv \"${DEBOOTSTAP_DIR_NAME}.tar\" \"${BASE_DIR_DOCKER}\""

echo "create docker image"
docker import "${DEBOOTSTAP_DIR}.tar" debootstrap-stretch

#rm -rf "${DEBOOTSTAP_DIR}"
rm "${DEBOOTSTAP_DIR}.tar"

echo "done"
