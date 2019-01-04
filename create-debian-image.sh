#!/bin/bash
set -eu -o pipefail

declare -r DEBOOTSTAP_DIR=$1



echo "** install requirements"
apt update
apt dist-upgrade -y
#apt install -y debootstrap fakechroot fakeroot
apt install -y debootstrap


echo "** debootstrap"
#fakechroot fakeroot debootstrap --variant=minbase stretch "${DEBOOTSTAP_DIR}" http://deb.debian.org/debian
#fakechroot fakeroot debootstrap --verbose --variant=minbase stretch "${DEBOOTSTAP_DIR}" http://deb.debian.org/debian
debootstrap --variant=minbase stretch "${DEBOOTSTAP_DIR}" http://deb.debian.org/debian



echo "** deactivate invoke of init.d scripts"
cat <<EOF > ${DEBOOTSTAP_DIR}/usr/sbin/policy-rc.d
#!/bin/sh
exit 101
EOF

chmod ugo+x ${DEBOOTSTAP_DIR}/usr/sbin/policy-rc.d



echo "** deactivate bootloader install with linux-image"
cat <<EOF > ${DEBOOTSTAP_DIR}/etc/kernel-img.conf
do_symlinks = yes
relative_links = yes
do_bootloader = no
do_bootfloppy = no
do_initrd = no
link_in_boot = no
EOF

echo "** remove devices not used in docker"
rm "${DEBOOTSTAP_DIR}"/dev/fd
rm "${DEBOOTSTAP_DIR}"/dev/full
rm "${DEBOOTSTAP_DIR}"/dev/null
rm "${DEBOOTSTAP_DIR}"/dev/ptmx
rm -rf "${DEBOOTSTAP_DIR}"/dev/pts
rm -f "${DEBOOTSTAP_DIR}"/dev/random
rm -rf "${DEBOOTSTAP_DIR}"/dev/shm
rm "${DEBOOTSTAP_DIR}"/dev/stderr
rm "${DEBOOTSTAP_DIR}"/dev/stdin
rm "${DEBOOTSTAP_DIR}"/dev/stdout
rm "${DEBOOTSTAP_DIR}"/dev/tty
rm -f "${DEBOOTSTAP_DIR}"/dev/urandom
rm -f "${DEBOOTSTAP_DIR}"/dev/zero
