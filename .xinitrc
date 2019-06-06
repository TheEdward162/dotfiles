#!/bin/env bash

userresources=$HOME/.Xresources
usermodmap=$HOME/.Xmodmap
sysresources=/etc/X11/xinit/.Xresources
sysmodmap=/etc/X11/xinit/.Xmodmap

# merge in defaults and keymaps
if [ -f "$sysresources" ]; then
	xrdb -merge "$sysresources"
fi

if [ -f "$sysmodmap" ]; then
	xmodmap "$sysmodmap"
fi

if [ -f "$userresources" ]; then
	xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
	xmodmap "$usermodmap"
fi

# load additional configs
if [ "$2" = "nvidia" ]; then
	XINIT_D="/etc/X11/nvidia/xinit/xinitrc.d"
else
	XINIT_D="/etc/X11/xinit/xinitrc.d"
fi

if [ -d "$XINIT_D" ]; then
	for f in "$XINIT_D/?*.sh" ; do
		[ -x "$f" ] && . "$f"
	done
	unset f
fi
unset XINIT_D

# additional nvidia specific settings
if [ "$2" = "nvidia" ]; then	
	xrandr --setprovideroutputsource modesetting NVIDIA-0
	xrandr --auto
fi

cd $HOME
# TODO: Maybe store the output somewhere instead
exec ck-launch-session dbus-launch --exit-with-session $HOME/bin/initscripts wm "$1" >/dev/null 2>&1
