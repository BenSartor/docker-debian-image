#!/bin/bash
set -eu -o pipefail

declare -r DEBOOTSTAP_DIR=$1



## debootstrap
apt update
apt dist-upgrade -y
apt install -y debootstrap fakechroot fakeroot
fakechroot fakeroot debootstrap --variant=minbase stretch "${DEBOOTSTAP_DIR}" http://deb.debian.org/debian



## deactivate invoke of init.d scripts
cat <<EOF > ${DEBOOTSTAP_DIR}/usr/sbin/policy-rc.d
#!/bin/sh
exit 101
EOF

chmod ugo+x ${DEBOOTSTAP_DIR}/usr/sbin/policy-rc.d



## deactivate bootloader install with linux-image
cat <<EOF > ${DEBOOTSTAP_DIR}/etc/kernel-img.conf
do_symlinks = yes
relative_links = yes
do_bootloader = no
do_bootfloppy = no
do_initrd = no
link_in_boot = no
EOF
