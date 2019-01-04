#!/bin/bash
set -eu -o pipefail

declare -r OUTPUR_DIR=$1
declare -r DEBOOTSTAP_DIR="debootstrap"



echo "** install requirements"
apt update
apt dist-upgrade -y
apt install -y debootstrap fakechroot fakeroot



echo "** debootstrap"
#fakechroot fakeroot debootstrap --variant=minbase stretch "${DEBOOTSTAP_DIR}" http://deb.debian.org/debian
#fakechroot fakeroot debootstrap --verbose --variant=minbase stretch "${DEBOOTSTAP_DIR}" http://deb.debian.org/debian
debootstrap --verbose --variant=minbase stretch "${DEBOOTSTAP_DIR}" http://deb.debian.org/debian



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



echo "** move resoult to shared directory"
mv "${DEBOOTSTAP_DIR}" "${DEBOOTSTAP_DIR}"