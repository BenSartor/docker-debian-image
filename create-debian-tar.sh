#!/bin/bash
set -eu -o pipefail

declare -r DESTINATION_TAR=${1:?"usage example: $0 /tmp/debootstrap.tar"}
declare -r DEBIAN_SUITE=${DEBIAN_SUITE:-"stretch"}


## use standard language for reproducibilty
export LC_ALL=C.UTF-8



declare -r DEBOOTSTAP_DIR=$(mktemp --directory --tmpdir "$(basename $0)-XXXXXXXXXX")
echo "** created temporary directory: ${DEBOOTSTAP_DIR}"

function cleanup {
    echo "** removing temporary directory: ${DEBOOTSTAP_DIR}"
    rm -rf "${DEBOOTSTAP_DIR}"
}
trap cleanup EXIT



echo "** install requirements"
LANG=C DEBIAN_FRONTEND=noninteractive apt-get update
LANG=C DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade --no-install-recommends --assume-yes
LANG=C DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --assume-yes debootstrap tar



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
#chroot "${DEBOOTSTAP_DIR}" bash -c "LANG=C DEBIAN_FRONTEND=noninteractive apt-get update"
#chroot "${DEBOOTSTAP_DIR}" bash -c "LANG=C DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --assume-yes apt-transport-https"

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

chroot "${DEBOOTSTAP_DIR}" bash -c "LANG=C DEBIAN_FRONTEND=noninteractive apt-get update"
chroot "${DEBOOTSTAP_DIR}" bash -c "LANG=C DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade --no-install-recommends --assume-yes"

declare -r DEBIAN_SOURCE_DATE=$(chroot "${DEBOOTSTAP_DIR}" bash -c "stat -c %y /usr/share/doc/*/changelog.Debian.gz | sort | tail -n 1")
echo "** DEBIAN_SOURCE_DATE=${DEBIAN_SOURCE_DATE}"



echo "** reduce image size"
cat <<EOF > "${DEBOOTSTAP_DIR}/etc/dpkg/dpkg.cfg.d/docker"
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

chroot "${DEBOOTSTAP_DIR}" bash -c "LANG=C DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --assume-yes --reinstall \$(dpkg --get-selections | grep -v deinstall | cut -f1 | sed \"s/:amd64\$//\")"



echo "** delete some caches"
chroot "${DEBOOTSTAP_DIR}" bash -c "LANG=C DEBIAN_FRONTEND=noninteractive apt-get clean"
#rm -rf "${DEBOOTSTAP_DIR}"/var/cache/apt/archives/ ## apt-get clean takes care of it
rm -rf "${DEBOOTSTAP_DIR}"/var/lib/apt/lists/*
rm "${DEBOOTSTAP_DIR}"/var/log/alternatives.log
rm "${DEBOOTSTAP_DIR}"/var/log/bootstrap.log
rm "${DEBOOTSTAP_DIR}"/var/log/dpkg.log
rm "${DEBOOTSTAP_DIR}"/var/log/apt/history.log
rm "${DEBOOTSTAP_DIR}"/var/log/apt/term.log



echo "** make reproducable"
echo "$(basename $DESTINATION_TAR .tar)" > "${DEBOOTSTAP_DIR}"/etc/hostname
rm "${DEBOOTSTAP_DIR}"/var/cache/ldconfig/aux-cache
chmod u+rwx "${DEBOOTSTAP_DIR}"
chmod go-rwx "${DEBOOTSTAP_DIR}"



echo "** creating tar with debian source date: ${DEBIAN_SOURCE_DATE}"
tar --clamp-mtime --mtime="${DEBIAN_SOURCE_DATE}" --exclude=dev -C "${DEBOOTSTAP_DIR}" -cf "${DESTINATION_TAR}" .
