#!/bin/sh

set -e

BOOT_DRIVE=/media/mmcblk0p1
PERSISTENT_DRIVE=/media/mmcblk0p2
WORKDIR=$PERSISTENT_DRIVE/upgrade
UNPACKDIR=/tmp/boot-upgrade
OVL_NAME="$(hostname).apkovl.tar.gz"

LOG=/dev/stderr
DRY_RUN=${DRY_RUN:-1}

VERSION=$1
if test -z "$VERSION"; then
	echo 'usage: upgrade.sh version'
	exit 1
fi

VERSION_MINOR=$(echo "$VERSION" | cut -d '.' -f '1-2')
UPGRADE_NAME="alpine-rpi-${VERSION}-aarch64.tar.gz"
UPGRADE_URL="https://dl-cdn.alpinelinux.org/alpine/v${VERSION_MINOR}/releases/aarch64/$UPGRADE_NAME"

_exec() {
	printf 'Executing "%s"\n' "$*"
	if test $DRY_RUN -eq 0; then
		$@
	fi
}

if test $DRY_RUN -eq 1; then
	echo 'Running in dry run mode'
fi

_exec mkdir $WORKDIR 2>/dev/null || true
_exec cp $BOOT_DRIVE/$OVL_NAME $PERSISTENT_DRIVE/upgrade
_exec mount -o remount,rw $BOOT_DRIVE

if ! test -e "$WORKDIR/$UPGRADE_NAME"; then
	_exec wget "$UPGRADE_URL" -O "$WORKDIR/$UPGRADE_NAME"
else
	echo 'File already downloaded'
fi
_exec mkdir $UNPACKDIR
_exec tar -C $UNPACKDIR -xzf $WORKDIR/$UPGRADE_NAME

_exec rm -r $BOOT_DRIVE/apks $BOOT_DRIVE/boot $BOOT_DRIVE/overlays || true
_exec cp -r $UNPACKDIR/apks $UNPACKDIR/boot $UNPACKDIR/overlays $UNPACKDIR/*.dtb $UNPACKDIR/*.bin $UNPACKDIR/*.dat $UNPACKDIR/*.elf $UNPACKDIR/config.txt $UNPACKDIR/.alpine-release $BOOT_DRIVE

_exec rm -r $UNPACKDIR

_exec sed -i "s/v[0-9]\.[0-9]\+/v${VERSION_MINOR}/g" /etc/apk/repositories
_exec apk update
_exec apk upgrade -i -a --update-cache

_exec update-conf -a -l
