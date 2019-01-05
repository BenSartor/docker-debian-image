#!/bin/bash
set -eu -o pipefail

declare -r DEBOOTSTAP_DIR=$1
mkdir "${DEBOOTSTAP_DIR}"



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
#chroot "${DEBOOTSTAP_DIR}" bash -c "LANG=C DEBIAN_FRONTEND=noninteractive apt-get update"
#chroot "${DEBOOTSTAP_DIR}" bash -c "LANG=C DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --assume-yes apt-transport-https"

cat <<EOF > "${DEBOOTSTAP_DIR}/etc/apt/sources.list"
## stretch
deb http://deb.debian.org/debian/ stretch main
#deb-src http://deb.debian.org/debian/ stretch main

## stretch-security
deb http://deb.debian.org/debian-security stretch/updates main
#deb-src http://deb.debian.org/debian-security stretch/updates main

## stretch-updates, previously known as 'volatile'
deb http://deb.debian.org/debian/ stretch-updates main
#deb-src http://deb.debian.org/debian/ stretch-updates main
EOF

chroot "${DEBOOTSTAP_DIR}" bash -c "LANG=C DEBIAN_FRONTEND=noninteractive apt-get update"
chroot "${DEBOOTSTAP_DIR}" bash -c "LANG=C DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade --no-install-recommends --assume-yes"



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
echo "stretch" > "${DEBOOTSTAP_DIR}"/etc/hostname
rm "${DEBOOTSTAP_DIR}"/var/cache/ldconfig/aux-cache



echo "** tar"
tar --exclude=dev -C "${DEBOOTSTAP_DIR}" -cf "${DEBOOTSTAP_DIR}.tar" .
