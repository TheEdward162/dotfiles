#!/bin/sh

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
