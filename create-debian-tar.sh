#!/bin/bash
set -eu -o pipefail

declare -r USAGE="usage example: $0 stretch /tmp/debootstrap.tar"
declare -r DEBIAN_SUITE=${1:?"${USAGE}"}
declare -r DESTINATION_TAR=${2:?"${USAGE}"}


## use standard language for reproducibilty
declare -rx LC_ALL=C.UTF-8
## apt-get options
declare -rx DEBIAN_FRONTEND="noninteractive"
declare -r APT_GET_OPTIONS="--no-install-recommends --assume-yes"



declare -r DEBOOTSTAP_DIR=$(mktemp --directory --tmpdir "$(basename $0)-XXXXXXXXXX")
declare -r DEBOOTSTAP_DIR_SLIM="${DEBOOTSTAP_DIR}-slim"
echo "** created temporary directory: ${DEBOOTSTAP_DIR}"

function cleanup {
    echo "** removing temporary directory: ${DEBOOTSTAP_DIR}"
    rm -rf "${DEBOOTSTAP_DIR}"
    echo "** removing temporary directory: ${DEBOOTSTAP_DIR_SLIM}"
    rm -rf "${DEBOOTSTAP_DIR_SLIM}"
}
trap cleanup EXIT



echo "** install requirements"
apt-get update
apt-get dist-upgrade ${APT_GET_OPTIONS}
apt-get install ${APT_GET_OPTIONS} debootstrap tar



echo "** debootstrap"
debootstrap --variant=minbase "${DEBIAN_SUITE}" "${DEBOOTSTAP_DIR}" http://deb.debian.org/debian



echo "** deactivate invoke of init.d scripts"
cat <<EOF > "${DEBOOTSTAP_DIR}/usr/sbin/policy-rc.d"
#!/bin/sh
exit 101
EOF
chmod ugo+x "${DEBOOTSTAP_DIR}/usr/sbin/policy-rc.d"

cat <<EOF > "${DEBOOTSTAP_DIR}/sbin/initctl"
#!/bin/sh
exit 0
EOF
chmod ugo+x "${DEBOOTSTAP_DIR}/sbin/initctl"



echo "** deactivate bootloader install with linux-image"
cat <<EOF > "${DEBOOTSTAP_DIR}/etc/kernel-img.conf"
do_symlinks = yes
relative_links = yes
do_bootloader = no
do_bootfloppy = no
do_initrd = no
link_in_boot = no
EOF



echo "** update debian packages"
#chroot "${DEBOOTSTAP_DIR}" bash -c "apt-get update"
#chroot "${DEBOOTSTAP_DIR}" bash -c "apt-get install ${APT_GET_OPTIONS} apt-transport-https"

cat <<EOF > "${DEBOOTSTAP_DIR}/etc/apt/sources.list"
## ${DEBIAN_SUITE}
deb http://deb.debian.org/debian/ ${DEBIAN_SUITE} main
#deb-src http://deb.debian.org/debian/ ${DEBIAN_SUITE} main

## ${DEBIAN_SUITE}-security
deb http://deb.debian.org/debian-security ${DEBIAN_SUITE}/updates main
#deb-src http://deb.debian.org/debian-security ${DEBIAN_SUITE}/updates main

## ${DEBIAN_SUITE}-updates, previously known as 'volatile'
deb http://deb.debian.org/debian/ ${DEBIAN_SUITE}-updates main
#deb-src http://deb.debian.org/debian/ ${DEBIAN_SUITE}-updates main
EOF

chroot "${DEBOOTSTAP_DIR}" bash -c "apt-get update"
chroot "${DEBOOTSTAP_DIR}" bash -c "apt-get dist-upgrade ${APT_GET_OPTIONS}"

declare -r DEBIAN_SOURCE_DATE=$(chroot "${DEBOOTSTAP_DIR}" bash -c "stat -c %y /usr/share/doc/*/changelog.Debian.gz | sort | tail -n 1")
echo "** DEBIAN_SOURCE_DATE=${DEBIAN_SOURCE_DATE}"



echo "** reduce image size"
cp -a "${DEBOOTSTAP_DIR}" "${DEBOOTSTAP_DIR_SLIM}"
cat <<EOF > "${DEBOOTSTAP_DIR_SLIM}/etc/dpkg/dpkg.cfg.d/docker"
path-exclude /usr/share/doc/*
path-exclude /usr/share/doc/kde/HTML/*/*
path-exclude /usr/share/gnome/help/*/*
path-exclude /usr/share/groff/*
path-exclude /usr/share/info/*
path-exclude /usr/share/linda/*
path-exclude /usr/share/lintian/overrides/*
path-exclude /usr/share/locale/*
path-exclude /usr/share/man/*
path-exclude /usr/share/omf/*/*-*.emf
path-include /usr/share/doc/*/copyright
path-include /usr/share/doc/kde/HTML/C/*
path-include /usr/share/gnome/help/*/C/*
path-include /usr/share/locale/all_languages'
path-include /usr/share/locale/currency/*'
path-include /usr/share/locale/l10n/*
path-include /usr/share/locale/languages'
path-include /usr/share/locale/locale.alias
path-include /usr/share/omf/*/*-C.emf
EOF

chroot "${DEBOOTSTAP_DIR_SLIM}" bash -c "apt-get install ${APT_GET_OPTIONS} --reinstall \$(dpkg --get-selections | grep -v deinstall | cut -f1 | sed \"s/:amd64\$//\")"
chroot "${DEBOOTSTAP_DIR_SLIM}" bash -c "apt-get remove --autoremove --purge --assume-yes tzdata"


function create-tar() {
    local -r L_DEBOOTSTAP_DIR=$1
    local -r L_DESTINATION_TAR=$2
    local -r L_DEBIAN_SOURCE_DATE=$3


    echo "** delete some caches in: ${L_DEBOOTSTAP_DIR}"
    chroot "${L_DEBOOTSTAP_DIR}" bash -c "apt-get clean"
    #rm -rf "${L_DEBOOTSTAP_DIR}"/var/cache/apt/archives/ ## apt-get clean takes care of it
    rm -rf "${L_DEBOOTSTAP_DIR}"/var/lib/apt/lists/*
    rm "${L_DEBOOTSTAP_DIR}"/var/log/alternatives.log
    rm "${L_DEBOOTSTAP_DIR}"/var/log/bootstrap.log
    rm "${L_DEBOOTSTAP_DIR}"/var/log/dpkg.log
    rm -f "${L_DEBOOTSTAP_DIR}"/var/log/apt/history.log
    rm -f "${L_DEBOOTSTAP_DIR}"/var/log/apt/term.log



    echo "** make reproducable: ${L_DEBOOTSTAP_DIR}"
    echo "$(basename $L_DESTINATION_TAR .tar)" > "${L_DEBOOTSTAP_DIR}"/etc/hostname
    rm "${L_DEBOOTSTAP_DIR}"/var/cache/ldconfig/aux-cache
    chmod u+rwx "${L_DEBOOTSTAP_DIR}"
    chmod go-rwx "${L_DEBOOTSTAP_DIR}"



    echo "** creating tar with debian source date: ${L_DEBIAN_SOURCE_DATE}"
    tar --clamp-mtime --mtime="${L_DEBIAN_SOURCE_DATE}" --exclude=dev -C "${L_DEBOOTSTAP_DIR}" -cf "${L_DESTINATION_TAR}" .
}

declare -r DESTINATION_TAR_SLIM="$(dirname ${DESTINATION_TAR})/$(basename ${DESTINATION_TAR} .tar)-slim.tar"
create-tar "${DEBOOTSTAP_DIR}"      "${DESTINATION_TAR}"      "${DEBIAN_SOURCE_DATE}"
create-tar "${DEBOOTSTAP_DIR_SLIM}" "${DESTINATION_TAR_SLIM}" "${DEBIAN_SOURCE_DATE}"
