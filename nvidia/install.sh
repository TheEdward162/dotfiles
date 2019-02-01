#!/bin/env bash

set -e

PREFIX="/opt/nvidia"

if [[ -x $1 ]]; then
	$1 --x-prefix="$PREFIX" --x-module-path="$PREFIX/lib/xorg/modules" --x-library-path="$PREFIX/lib"\ --x-sysconfig-path="$PREFIX/share/X11"\
		--opengl-prefix="$PREFIX" --compat32-prefix="$PREFIX" --utility-prefix="$PREFIX" --documentation-prefix="$PREFIX"\
		--compat32-libdir="lib32" --application-profile-path="$PREFIX/share/nvidia"\
		--no-x-check --no-kernel-module
	
	echo "Installation done, now running some dirty hacks..."

	# these libraries are broken
	for file in $PREFIX/lib/xorg/modules/*wfb*; do
		# -e operator returns false for broken symlinks...
		if [[ -e $file || -L $file ]]; then
			echo "Removing file $file"
			rm "$file"
		fi
	done

	# the installation breaks these packages by replacing and removing their files, so we unbreak them by reinstalling them
	xbps-install -fy libGL libEGL libGL-32bit libEGL-32bit
else
	echo "Error: First argument must be an executable file"
fi
