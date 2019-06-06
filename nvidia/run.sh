#!/bin/env bash

# CONFIG VARIABLES
BUS_ID=0000:01:00.0

MODULE_DRIVER="nvidia"
MODULES_LOAD=(nvidia_uvm nvidia_modeset "nvidia_drm modeset=1")
MODULES_UNLOAD=(nvidia_drm nvidia_modeset nvidia_uvm)

DEVICE_PATH="/sys/bus/pci/devices/$BUS_ID"
DRIVER_PATH="/sys/bus/pci/drivers/nvidia"
LIBRARY_PATHS="/opt/nvidia/fakeroot/lib /opt/nvidia/fakeroot/lib32"

XINITRC_PATH="$HOME/.xinitrc"
CONFIG_PATH="nvidia/xorg.conf"
CONFIGDIR_PATH="nvidia/xorg.conf.d"

BUS_RESCAN_WAIT_SEC=1

FREE_DISPLAY=":-1"
calculate_display() {
	local num=-1
	local path="/tmp/.X11-unix"
	
	while [[ true ]]; do
		num=$((num + 1))
		if [[ -S "$path/X$num" ]]; then
			continue
		fi

		break
	done

	FREE_DISPLAY=":$num"
}

activate_gpu() {
	if [[ ! -d $DEVICE_PATH ]]; then
		echo "Device $BUS_ID not found, rescanning PCI..."
		sudo tee /sys/bus/pci/rescan <<< 1
		sleep $BUS_RESCAN_WAIT_SEC
	fi

	if [[ ! -d $DEVICE_PATH ]]; then
		echo "Device $BUS_ID still not found, quitting"
		return 5
	fi
	
	# turn device on
	echo "Powering device $BUS_ID on"
	sudo tee "$DEVICE_PATH/power/control" <<< on > /dev/null || return 3
	echo ""

	# load driver module
	echo "Loading driver module $MODULE_DRIVER"
	sudo modprobe $MODULE_DRIVER || return 2

	# bind driver
	echo "Binding driver to device $BUS_ID"
	sudo tee "$DRIVER_PATH/bind" <<< $BUS_ID > /dev/null || echo "Driver already bound"
	echo ""

	# load additional modules
	for module in "${MODULES_LOAD[@]}"; do
		echo "Loading module $module"
		sudo modprobe $module || return 1
	done
}

deactivate_gpu() {
	local error=$1
	
	if [[ $error -lt 2 ]]; then
		for module in "${MODULES_UNLOAD[@]}"; do
			echo "Unloading module $module"
			sudo modprobe -r $module
		done
		echo ""
	fi

	if [[ $error -lt 3 ]]; then
		# unbind driver
		if [[ -e "$DRIVER_PATH/$BUS_ID" ]]; then
			echo "Unbinding driver from device $BUS_ID"
			sudo tee "$DRIVER_PATH/unbind" <<< $BUS_ID
			echo ""
		else
			echo "Warning, could not unbind driver because it was not bound"
			echo ""
		fi

		echo "Unloading driver module $MODULE_DRIVER"
		sudo modprobe -r $MODULE_DRIVER
	fi

	# set device power to auto
	echo "Setting device $BUS_ID power control to auto"
	sudo tee "$DEVICE_PATH/power/control" <<< auto > /dev/null

	# Since the driver is unloaded and the device power control is
	# set to auto, it should automatically power off at this point.
	# This should be true for "newer" devices, whatever that means.
}

run_x() {
	local wm="$1"

	calculate_display
	local tty_number=$(fgconsole)
	echo "Calculated display $FREE_DISPLAY and TTY $tty_number"

	echo "Adding $LIBRARY_PATHS to ldconfig paths"
	sudo ldconfig $LIBRARY_PATHS

	echo "Running X"
	xinit "$XINITRC_PATH" "$wm" nvidia -- $FREE_DISPLAY "vt$tty_number" -nolisten tcp -br -config "$CONFIG_PATH" -configdir "$CONFIGDIR_PATH"
	echo ""

	echo "Resetting ldconfig"
	sudo ldconfig
}


activate_gpu
error=$?

echo ""
if [[ $error -eq 0 ]]; then
	run_x "$1"
else
	echo "Error ($error): Could not activate GPU"
fi
echo ""

deactivate_gpu $error
