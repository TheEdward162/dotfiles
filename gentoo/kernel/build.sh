#!/bin/sh

# need sys-kernel/gentoo-sources
# doas eselect kernel set <n>

cp ./config /usr/src/linx/.config
cd /usr/src/linux
make menuconfig
cd -

cp /usr/src/linux/.config ./config
cd /usr/src/linux

make -j12
make modules_install
make install

grub-mkconfig -o /boot/grub/grub.cfg
cd -
