#!/bin/sh

set -e

BOOT_PATH='/media/mmcblk0p1'

_log() {
	printf "[$(date -Iseconds)] $@\n"
}

_log "Started headless"

CONFIG_FILE=${CONFIG_FILE:-$BOOT_PATH/headless.txt}
if [ ! -f $CONFIG_FILE ]; then
	_log "Config file $CONFIG_FILE not present, skipping"
	exit 0
fi

runlevel() {
	_log "Creating network runlevel"
	mkdir -p /etc/runlevels/network
	ln -s /etc/runlevels/network /etc/runlevels/default
}

networking() {
	_log "Setting up hostname"
	local hostname=$(awk '($1 == "hostname") { print $2 }' $CONFIG_FILE)
	echo $hostname >/etc/hostname
	hostname -F /etc/hostname

	_log "Setting up networking for $hostname"
	cat << EOF >/etc/network/interfaces
auto lo
iface lo inet loopback

auto wlan0
iface wlan0 inet dhcp
hostname $hostname
EOF
	rc-update add networking network
	rc-service networking restart
}

wifi() {
	_log "Setting up wifi"
	apk add wpa_supplicant

	local conf_file=/etc/wpa_supplicant/wpa_supplicant.conf
	local ctrl_dir=/var/run/wpa_supplicant
	_log "Generating passphrases"
	mkdir -p /etc/wpa_supplicant
	cat << EOF >$conf_file
country=de
ctrl_interface=DIR=$ctrl_dir GROUP=wheel
EOF
	awk '($1 == "wifi") { print $2,$3 }' $CONFIG_FILE | xargs -n 2 wpa_passphrase >>$conf_file
	rc-update add wpa_supplicant network
	rc-service wpa_supplicant restart

	_log "Waiting for connection"
	# wait for wpa_supplicant
	while ! test -e $ctrl_dir/wlan0; do
		sleep 1
	done
	# wait for wifi connection
	while ! wpa_cli -p $ctrl_dir -i wlan0 status | grep -q wpa_state=COMPLETED; do
		sleep 1
	done
	# wait for dhcp
	while ! test -f /etc/resolv.conf; do
		sleep 1
	done
}

apk_setup() {
	_log "Setting up apk"
	setup-apkcache "$BOOT_PATH/apkcache"

	local apkrepo=$(awk '($1 == "apkrepo") { print $2 }' $CONFIG_FILE)
	cat << EOF >/etc/apk/repositories
$BOOT_PATH/apks

$apkrepo/main
$apkrepo/community
EOF

	apk update
}

ssh_keys() {
	_log "Setting up ssh keys"
	mkdir -p /root/.ssh
	awk '($1 == "ssh") { print $2,$3,$4 }' $CONFIG_FILE >>/root/.ssh/authorized_keys
	_log "Authorized keys:\n" $(cat /root/.ssh/authorized_keys)
}

sshd() {
	_log "Setting up sshd"
	apk add dropbear dropbear-scp # openssh-sftp-server dropbear-scp
	echo 'DROPBEAR_OPTS="-s -p 4222"' >>/etc/conf.d/dropbear
	rc-update add dropbear network
	rc-service dropbear restart
}

chrony() {
	_log "Setting up chrony"
	apk add chrony
	rc-update add chronyd network
	rc-service chronyd restart
}

# set up the basics and get online
runlevel
networking
wifi

# start by setting up ntp and remote sources
chrony
apk_setup

# then setup up ssh (fetches dropbear)
ssh_keys
sshd

_log "Done"
rc-update del headless default

# don't forget to modify:
# /etc/motd
# /etc/fstab
# /etc/inittab
# if setting up lbu: lbu add /root/.ssh/authorized_keys
