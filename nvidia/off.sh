#!/bin/env bash

DEVICE="0000:01:00.0"
DRIVER_PATH="/sys/bus/pci/drivers/nvidia"
DEVICE_PATH="/sys/bus/pci/devices"

echo "Ensuring nvidia GPU is off"

modprobe nvidia
tee "$DRIVER_PATH/unbind" <<< $DEVICE
modprobe -r nvidia

tee "$DEVICE_PATH/$DEVICE/power/control" <<< auto

# ensure that ldconfig is reloaded
ldconfig

echo ""
