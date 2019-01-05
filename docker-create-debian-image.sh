#!/bin/bash
set -eu -o pipefail

declare -r SKIP_DOCKER_IMPORT=${SKIP_DOCKER_IMPORT:-"false"}

declare -r GREADLINK=$(which greadlink)
declare -r READLINK=${GREADLINK:-"$(which readlink)"}

declare -r BASE_DIR="$(dirname $(${READLINK} -f $0))"
declare -r BASE_DIR_DOCKER="/debian-docker"

declare -r DOCKER_SCRIPT="${BASE_DIR_DOCKER}/create-debian-tar.sh"
declare -r DEBOOTSTAP_DIR_NAME="debootstrap"
declare -r DEBOOTSTAP_TAR="${BASE_DIR}/${DEBOOTSTAP_DIR_NAME}.tar"

if [ -e "${DEBOOTSTAP_TAR}" ] ; then
    echo "error directory already exists: ${DEBOOTSTAP_TAR}"
    exit 1
fi

echo "debootstrab in a docker container"
docker run -it --privileged --rm -v "${BASE_DIR}":"${BASE_DIR_DOCKER}" debian:buster-slim \
    bash -c "\"${DOCKER_SCRIPT}\" \"${DEBOOTSTAP_DIR_NAME}\" ; mv \"${DEBOOTSTAP_DIR_NAME}.tar\" \"${BASE_DIR_DOCKER}\""


if [[ "${SKIP_DOCKER_IMPORT}" == "false" ]] ; then
    echo "create docker image"
    docker import "${DEBOOTSTAP_TAR}" debootstrap-stretch
    rm "${DEBOOTSTAP_TAR}"
fi

echo "done"
