#!/bin/bash
set -eu -o pipefail

declare -r DEBOOTSTAP_DIR=$1



echo "** install requirements"
apt update
apt dist-upgrade -y
apt install -y debootstrap tar


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



echo "** delete some caches"
rm -rf "${DEBOOTSTAP_DIR}"/var/cache/apt/archives/
rm -rf "${DEBOOTSTAP_DIR}"/var/lib/apt/lists/*
rm "${DEBOOTSTAP_DIR}"/var/log/alternatives.log
rm "${DEBOOTSTAP_DIR}"/var/log/bootstrap.log
rm "${DEBOOTSTAP_DIR}"/var/log/dpkg.log



echo "** tar"
tar --exclude=dev -C "${DEBOOTSTAP_DIR}" -cf "${DEBOOTSTAP_DIR}.tar" .
