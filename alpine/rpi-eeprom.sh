#!/bin/sh

# stolen from https://pkgs.alpinelinux.org/package/edge/testing/aarch64/raspberrypi-usbboot
# also need /usr/share/rpiboot/recovery/rpi-eeprom-config from raspberrypi-usbboot package, but it is outdated so we download our own

set -e
# set -x

RPI_EEPROM_CONFIG=${RPI_EEPROM_CONFIG:-/usr/share/rpiboot/recovery/rpi-eeprom-config}

get_current_config() {
	# also can do https://github.com/raspberrypi/rpi-eeprom/blob/master/rpi-eeprom-update#L117
	vcgencmd bootloader_version
	vcgencmd bootloader_config
	lspci -d 1106:3483 -xxx | awk '/^50:/ { print "VL805 FW version: " $5 $4 $3 $2 }'
}

download() {
	local out_dir="$1"
	local fw="$2" # firmware-2712
	local date="$3" # 2025-01-07
	local channel="$4" # default, latest
	local branch="$5" # master
	local vl805_version="$6" # 000138c0

	wget -q -O "$out_dir/recovery.bin" "https://github.com/raspberrypi/rpi-eeprom/raw/refs/heads/$branch/$fw/$channel/recovery.bin"
	wget -q -O "$out_dir/pieeprom-$date.bin" "https://github.com/raspberrypi/rpi-eeprom/raw/refs/heads/$branch/$fw/$channel/pieeprom-$date.bin"
	if [ "$fw" = "firmware-2711" ] && [ -n "$vl805_version" ]; then
		wget -q -O "$out_dir/vl805-$vl805_version.bin" "https://github.com/raspberrypi/rpi-eeprom/raw/refs/heads/$branch/$fw/$channel/vl805-$vl805_version.bin"
	fi
	wget -q -O "$out_dir/rpi-eeprom-config" "https://github.com/raspberrypi/rpi-eeprom/raw/refs/heads/$branch/rpi-eeprom-config"
	chmod +x "$out_dir/rpi-eeprom-config"
}

_update_digest() {
	local in_file="$1"
	local out_file="$2"

	sha256sum "$in_file" | awk '{print $1}' >"$out_file"
	echo "ts: $(date -u +%s)" >>"$out_file"
}

generate_update() {
	local in_eeprom="$1" # pieeprom.bin
	local in_config="$2" # boot.conf
	local bootfs="$3" # /boot
	local in_vl805="$4" # vl805.bin

	local out_eeprom="${bootfs}/pieeprom.upd"
	local out_sig="${bootfs}/pieeprom.sig"

	$RPI_EEPROM_CONFIG --config "$in_config" --out "$out_eeprom" "$in_eeprom"
	_update_digest "$out_eeprom" "$out_sig"

	if [ -f "$in_vl805" ]; then
		local out_vl805="${bootfs}/vl805.bin"
		local out_vl805_sig="${bootfs}/vl805.sig"
		mv "$in_vl805" "$out_vl805"
		_update_digest "$out_vl805" "$out_vl805_sig"
	fi
}

cleanup_update() {
	local bootfs="$1" # /boot

	if [ -z "$bootfs" ]; then
		print_help
		exit 1
	fi

	rm -f "$bootfs/pieeprom.upd" "$bootfs/pieeprom.sig" "$bootfs/recovery.bin" "$bootfs/recovery.000" "$bootfs/vl805.bin" "$bootfs/vl805.sig"
}

do_update_hardcoded() {
	local config="$1"
	local fw="firmware-2711"
	local date="2024-12-07"
	local vl805_version="000138c0"
	
	local bootfs="/boot"
	local stage_dir="/opt/rpi-eeprom"
	mkdir -p $stage_dir


	download "$stage_dir" $fw $date latest master $vl805_version
	mv "$stage_dir/recovery.bin" "$bootfs/recovery.bin"
	RPI_EEPROM_CONFIG="$stage_dir/rpi-eeprom-config"
	generate_update "$stage_dir/pieeprom-$date.bin" "$config" $bootfs "$stage_dir/vl805-$vl805_version.bin"
}

print_help() {
	printf "usage: update.sh command\ncommands:\n\t%s\n\t%s\n\t%s\n\t%s\n\t%s\n" \
		"get-config" \
		"update in_eeprom in_config bootfs" \
		"download out_dir fw date channel branch [vl805_version]" \
		"cleanup bootfs" \
		"rpi-eeprom-update in_config"
}

case "$1" in
	get-config)
		get_current_config
	;;

	update)
		shift
		generate_update "$@"
	;;

	download)
		shift
		download "$@"
	;;

	cleanup)
		shift
		cleanup_update "$@"
	;;

	rpi-eeprom-update)
		shift
		do_update_hardcoded "$@"
	;;

	*)
		print_help
		exit 0
	;;
esac
