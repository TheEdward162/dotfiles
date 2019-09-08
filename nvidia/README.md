## NVIDIA hacks for NVIDIA Optimus

### Dependencies
* `nvidia-dkms` package for the kernel modules.
* `libGL libEGL` mesa drivers (optionally also `libGL-32bit libEGL-32bit`).
* `bbswitch` must **NOT** be installed/loaded, or the run script will hang.
* `xrandr xorg`
* any WM

You will also need to blacklist the nvidia kernel modules so that they won't get loaded at boot and your NVIDIA card will stay off until you need it. You can do this by creating a file in `/etc/modprobe.d` with any name (usually `nvidia.conf`) and the following text:
```
blacklist nvidia
blacklist nvidia-drm
blacklist nvidia-modeset
blacklist nvidia-uv
blacklist nouveau
```

You might also need to remove the `xorg-video-drivers` package in case you have it installed (see issue [#1](https://github.com/TheEdward162/dotfiles/issues/1)). Alternatively, you can try adding `export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json` to your nvidia `.xinitrc`.

Note: I've had problems where the GPU was sometimes on even though the drivers were not loaded, a simple workaround is to run the `off.sh` script at boot.

### TL;DR
If you don't want to change any paths or scripts:
```
git clone https://github.com/TheEdward162/dotfiles.git
cd dotfiles/nvidia
sudo mkdir /opt/nvidia
sudo cp install.py run.sh /opt/nvidia/

sudo mkdir /etc/X11/nvidia
sudo cp -r xorg.conf xorg.conf.d /etc/X11/nvidia/

cd /opt/nvidia
sudo python3 ./install.py
```
Now switch to a TTY that doesn't have X session running.
```
/opt/nvidia/run.sh
```
This will run `xinit ~/.xinitrc "" nvidia`. Make sure your `~/.xinitrc` has at least these two lines in it:
```
xrandr --setprovideroutputsource modesetting NVIDIA-0
xrandr --auto
```
and that it launches a correct wm session after that.

You should now be running your X session on your NVIDIA card.

### install.py
*This script is partly a hack, use at your own risk.*

This script prepares a fakeroot and uses xbps-install to install the `nvidia nvidia-libs nvidia-libs-32bit` packages into it so that they don't collide with your intel packages (namely `libGL libEGL`). It creates a `fakeroot` directory in current working directory and then creates `usr/lib usr/lib32` folders inside. It also creates symlinks `fakeroot/lib -> fakeroot/usr/lib` and `fakeroot/lib32 -> fakeroot/usr/lib32`.

This script also creates a fake xbps package database in `fakeroot/var/db/xbps/pkgdb-0.38.plist` to trick xbps into thinking all the required packages except for the nvidia driver ones are actually in the fakeroot. This is a **hack**, but it should work as long as the required packages are actually installed on your system.

### xorg
Now you need to create a valid xorg configuration somewhere in `/etc/X11` (for example `/etc/X11/nvidia`). Copy `xorg.conf` and `xorg.conf.d` there. If you installed your nvidia libraries in a different location, you will need to edit `xorg.conf` as well. Edit the lines:
```
Section "Files"
	ModulePath "/opt/nvidia/fakeroot/lib"
	ModulePath "/opt/nvidia/fakeroot/lib/vdpau"
  
	ModulePath "/opt/nvidia/fakeroot/lib32"
	ModulePath "/opt/nvidia/fakeroot/lib32/vdpau"
  
	ModulePath "/opt/nvidia/fakeroot/lib/xorg/modules"
	ModulePath "/opt/nvidia/fakeroot/lib/xorg/modules/drivers"
	ModulePath "/opt/nvidia/fakeroot/lib/xorg/modules/extensions"
	ModulePath "/opt/nvidia/fakeroot/lib/tls"

	ModulePath "/usr/lib/xorg/modules"
EndSection
```
so that all the entries starting with `/opt/nvidia/fakeroot` start with your path instead. Also remove lines `ModulePath "/opt/nvidia/fakeroot/lib32"` and `ModulePath "/opt/nvidia/fakeroot/lib32/vdpau"` if you aren't installing/using 32bit libraries.

Now you need to prepare your `xinitrc` somewhere (default `$HOME/.xinitrc`, but make sure it differentiates between running xorg on intel and nvidia - `run.sh` will set `$2` to `nvidia`, you can check for that). It needs to contain at least these two lines for nvidia xorg session to work (otherwise you get a black screen):
```
xrandr --setprovideroutputsource modesetting NVIDIA-0
xrandr --auto
```

If you changed the paths of `xorg.conf`, `xorg.conf.d` or `xinirc`, change the `run.sh` script to point to them. Specifically the lines:
```
XINITRC_PATH="$HOME/.xinitrc"
CONFIG_PATH="nvidia/xorg.conf"
CONFIGDIR_PATH="nvidia/xorg.conf.d"
```
`XINITRC_PATH` expects an absolute path to your `xinitrc`. `CONFIG_PATH` and `CONFIGDIR_PATH` need a path relative to `/etc/X11`.

### run.sh
*This is mostly just a copy of [nvidia-xrun](https://github.com/Witko/nvidia-xrun) but instead of removing the device from the pci bus (which does power it down, but only until the next rescan), it unbinds the nvidia driver from it before unloading it, which makes the card power down without having to remove it.*

If you aren't installing/using 32bit libraries, change `LIBRARY_PATHS="/opt/nvidia/fakeroot/lib /opt/nvidia/fakeroot/lib32"` to `LIBRARY_PATHS="/opt/nvidia/fakeroot/lib"`.

After you have installed the nvidia libraries, set up your xorg config files and changed the `run.sh` script to point to them, all that's left is to run it. Switch to a TTY that doesn't have X session running on it. You can do this using `Ctrl+Alt+FX` keys. If you are currently in console mode, there is no need to switch to a different TTY.

The script will start an X server and run your `XINITRC_PATH` script with the first argument passed from it and the second set to `nvidia` (so `./run.sh i3` will run `XINITRC_PATH i3 nvidia`).

Your X session should now be running on NVIDIA card. This can be checked with programs such as `glmark2`. After closing that session, your nvidia card should power off. Beware that rebooting/powering off from within the WM session will **NOT** run the closing part of the script. The only real impact of this is that your Intel libGL libraries will be shadowed by NVIDIA ones. You can run `sudo ldconfig` afterwards to fix this (or just run the `off.sh` script at boot).

### off.sh
Small script that performs steps to ensure that the NVIDIA Gpu is off and that correct `ldconfig` is loaded. Run this as root at boot.

### More info
* [nvidia-xrun](https://github.com/Witko/nvidia-xrun) - inspiration for `run.sh`
* [this void-packages issue](https://github.com/voidlinux/void-packages/issues/5863) - issue with conflicting opengl libraries
* [Void Wiki Steam article](https://wiki.voidlinux.org/Steam) - has a guide on 32bit libraries
