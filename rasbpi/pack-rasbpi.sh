#!/bin/sh

LOG_PATH=/dev/stderr
DRY_RUN=0

while [ ! -z "$1" ]; do
	case "$1" in
		-q)
			LOG_PATH=/dev/null
		;;

		-d)
			DRY_RUN=1
		;;
	esac
shift
done

HOME_1='
.zshrc
.zprofile'

HOME_2='
bin/hive
bin/initscripts'

HOME_3='
.config/mpv/input.conf
.config/mpv/mpv.conf
.config/sway/config
.config/waybar/config
.config/waybar/style.css
.config/waybar/style.less
.config/transmission-daemon/settings.json'

ROOT_1='
etc/conf.d/ocron
etc/init.d/ocron
etc/vsftpd/vsftpd.conf
etc/apk/repositories
'

ROOT_2='
usr/local/etc/arsenal/config.ron
usr/local/etc/ocron/config
usr/local/bin/hdd-idle'

backup() {
	local from=$1
	local to=$2

	printf 'Backing up "%s" to "%s"\n' "$from" "$to"
	if [ $DRY_RUN -eq 0 ]; then
		mkdir -p $(dirname "$to")
		cp -Pp "$from" "$to"
	fi
}

diff_backup() {
	local base=$1
	local files=$2

	for file in $files; do
		local path="$base/$file"

		if [ -f "$path" ]; then
			if [ -f "./$file" ]; then
				diff -q "$path" "./$file" >/dev/null
				if [ ! $? ]; then
					backup "$path" "./$file"
				else
					printf 'Skipping "%s" because it has not changed\n' "$path" >$LOG_PATH
				fi
			else
				backup "$path" "./$file"
			fi
		else
			printf '"%s" does not exist or is not a file\n' "$path" >$LOG_PATH
		fi
	done
}

diff_backup '/home/rasbpi' "$HOME_1"
diff_backup '/home/rasbpi' "$HOME_2"
diff_backup '/home/rasbpi' "$HOME_3"

diff_backup '/' "$ROOT_1"
diff_backup '/' "$ROOT_2"