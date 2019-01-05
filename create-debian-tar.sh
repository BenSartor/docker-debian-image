#!/bin/bash
set -eu -o pipefail

declare -r DEBOOTSTAP_DIR=$1



echo "** install requirements"
LANG=C DEBIAN_FRONTEND=noninteractive apt-get update
LANG=C DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade --no-install-recommends --assume-yes
LANG=C DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --assume-yes debootstrap tar


echo "** debootstrap"
debootstrap --variant=minbase stretch "${DEBOOTSTAP_DIR}" http://deb.debian.org/debian



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
chroot "${DEBOOTSTAP_DIR}" bash -c "LANG=C DEBIAN_FRONTEND=noninteractive apt-get update"
chroot "${DEBOOTSTAP_DIR}" bash -c "LANG=C DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --assume-yes apt-transport-https"

cat <<EOF > "${DEBOOTSTAP_DIR}/etc/apt/sources.list"
## stretch
deb https://deb.debian.org/debian/ stretch main
#deb-src https://deb.debian.org/debian/ stretch main

## stretch-security
deb https://deb.debian.org/debian-security stretch/updates main
#deb-src https://deb.debian.org/debian-security stretch/updates main

## stretch-updates, previously known as 'volatile'
deb https://deb.debian.org/debian/ stretch-updates main
#deb-src https://deb.debian.org/debian/ stretch-updates main
EOF

chroot "${DEBOOTSTAP_DIR}" bash -c "LANG=C DEBIAN_FRONTEND=noninteractive apt-get update"
chroot "${DEBOOTSTAP_DIR}" bash -c "LANG=C DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade --no-install-recommends --assume-yes"




cat <<EOF > "${DEBOOTSTAP_DIR}/etc/dpkg/dpkg.cfg.d/docker"
path-exclude=/usr/share/locale/*
path-exclude=/usr/share/man/*
path-exclude=/usr/share/doc/*
EOF

#dpkg --get-selections > selections
#dpkg --clear-selections
#dpkg --set-selections < selections
#apt-get --reinstall dselect-upgrade
#LANG=C DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --assume-yes --reinstall $(dpkg --get-selections | grep -v deinstall | cut -f1 | sed "s/:amd64$//")


echo "** delete some caches"
rm -rf "${DEBOOTSTAP_DIR}"/var/cache/apt/archives/
rm -rf "${DEBOOTSTAP_DIR}"/var/lib/apt/lists/*
rm "${DEBOOTSTAP_DIR}"/var/log/alternatives.log
rm "${DEBOOTSTAP_DIR}"/var/log/bootstrap.log
rm "${DEBOOTSTAP_DIR}"/var/log/dpkg.log



echo "** tar"
tar --exclude=dev -C "${DEBOOTSTAP_DIR}" -cf "${DEBOOTSTAP_DIR}.tar" .
