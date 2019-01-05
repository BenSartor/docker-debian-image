#!/bin/bash
set -eu -o pipefail

declare -r SKIP_DOCKER_IMPORT=${SKIP_DOCKER_IMPORT:-"false"}
declare -r DOCKER_BUILD_IMAGE=${DOCKER_BUILD_IMAGE:-"debian:stretch-slim"}



declare -r GREADLINK=$(which greadlink)
declare -r READLINK=${GREADLINK:-"$(which readlink)"}

declare -r BASE_DIR="$(dirname $(${READLINK} -f $0))"
declare -r BASE_DIR_DOCKER="/debian-docker"

declare -r DOCKER_SCRIPT="${BASE_DIR_DOCKER}/create-debian-tar.sh"
declare -r DEBOOTSTAP_TAR_NAME="debootstrap.tar"
declare -r DEBOOTSTAP_TAR="${BASE_DIR}/${DEBOOTSTAP_TAR_NAME}"


if [ -e "${DEBOOTSTAP_TAR}" ] ; then
    echo "error directory already exists: ${DEBOOTSTAP_TAR}"
    exit 1
fi

echo "debootstrap in docker container: ${DOCKER_BUILD_IMAGE}"
docker run -it --privileged --rm -v "${BASE_DIR}":"${BASE_DIR_DOCKER}" "${DOCKER_BUILD_IMAGE}" "${DOCKER_SCRIPT}" "${BASE_DIR_DOCKER}/${DEBOOTSTAP_TAR_NAME}"


if [[ "${SKIP_DOCKER_IMPORT}" == "false" ]] ; then
    echo "create docker image"
    docker import "${DEBOOTSTAP_TAR}" debootstrap-stretch
    rm "${DEBOOTSTAP_TAR}"
fi

echo "done"
