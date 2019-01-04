#!/bin/bash
set -eu -o pipefail

declare -r DEBOOTSTAP_DIR=$1


apt update
apt dist-upgrade -y
apt install -y debootstrap fakechroot fakeroot
fakechroot fakeroot debootstrap --variant=minbase stretch "${DEBOOTSTAP_DIR}" http://deb.debian.org/debian

