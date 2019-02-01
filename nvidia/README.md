## NVIDIA hacks for NVIDIA Optimus

### Dependencies
* `nvidia-dkms` package for the kernel modules.
* `libGL libEGL` mesa drivers (optionally also `libGL-32bit libEGL-32bit`).
* `bbswitch` must **NOT** be installed/loaded, or the run script will hang.
* `xrandr xorg`
* any WM

You will also need to blacklist the nvidia kernel modules so that they won't get loaded at boot and your NVIDIA card will stay off until you need it. You can do this by creating a file in `/usr/lib/modprobe.d` with any name and the following text:
```
blacklist nvidia
blacklist nvidia-drm
blacklist nvidia-modeset
blacklist nvidia-uv
blacklist nouveau
```

### TL;DR
If you don't want to change any paths or scripts:
```
git clone https://github.com/TheEdward162/dotfiles.git
cd dotfiles/nvidia
sudo mkdir /opt/nvidia
sudo cp install.sh run.sh /opt/nvidia/

sudo mkdir /etc/X11/nvidia
sudo cp -r xorg.conf xorg.conf.d /etc/X11/nvidia/
```
Now download the nvidia driver binary from nvidia driver download page and put it in `/opt/nvidia`.
```
cd /opt/nvidia
sudo ./install.sh ./NVIDIA-Linux-x86_64-XXX.XX.run
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

### install.sh
*This script is a terrible hack, use at your own risk.*

First thing to do is to edit the `$PREFIX` variable in the `install.sh` script. That way you can control where the nvidia libraries will be installed. Also if you are not installing/using 32bit libraries (you will need to select no in the nvidia installer), delete them from the `install.sh` script from line `xbps-install -fy libGL libEGL libGL-32bit libEGL-32bit` (make it `xbps-install -fy libGL libEGL`).

Next step is to obtain the `NVIDIA-Linux-x86_64-XXX.XX.run` binary from nvidia driver download page. Then run `sudo ./install.sh ./NVIDIA-Linux-x86_64-XXX.XX.run` and basically say yes to everything. This will mess up your mesa installation, but the script should fix that later.

The script should now delete broken nvidia fwb libraries from `$PREFIX/lib/xorg/modules` and then force-reinstall your `libGL` and `libEGL` packages (probably also `libGL-32bit` and `libEGL-32bit`) because the nvidia installer changes them even though it shouldn't. If the script runs successfully, you should now have a working mesa installation and a separate nvidia instalation in `$PREFIX` (default in `/opt/nvidia`).

*Note: This could probably be done with chroot to avoid having to reinstall system libraries, but I couldn't get it to work yet.*

### xorg
Now you need to create a valid xorg configuration somewhere in `/etc/X11` (for example `/etc/X11/nvidia`). Copy `xorg.conf` and `xorg.conf.d` there. If you changed the `$PREFIX` variable in `install.sh`, you will need to edit `xorg.conf` as well. Edit the lines:
```
Section "Files"
	ModulePath "/opt/nvidia/lib"
	ModulePath "/opt/nvidia/lib/vdpau"
  
	ModulePath "/opt/nvidia/lib32"
	ModulePath "/opt/nvidia/lib32/vdpau"
  
	ModulePath "/opt/nvidia/lib/xorg/modules"
	ModulePath "/opt/nvidia/lib/xorg/modules/drivers"
	ModulePath "/opt/nvidia/lib/xorg/modules/extensions"
	ModulePath "/opt/nvidia/lib/tls"

	ModulePath "/usr/lib/xorg/modules"
EndSection
```
so that all the entries starting with `/opt/nvidia` start with your `$PREFIX` instead. Also remove lines `ModulePath "/opt/nvidia/lib32"` and `ModulePath "/opt/nvidia/lib32/vdpau"` if you aren't installing/using 32bit libraries.

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

If you aren't installing/using 32bit libraries, change `LIBRARY_PATHS="$PREFIX/lib $PREFIX/lib32"` to `LIBRARY_PATHS="$PREFIX/lib"` where `$PREFIX` is the same value that you used in `install.sh` (default `/opt/nvidia`).

After you have installed the nvidia libraries, set up your xorg config files and changed the `run.sh` script to point to them, all that's left is to run it. Switch to a TTY that doesn't have X session running on it. You can do this using `Ctrl+Alt+FX` keys. If you are currently in console mode, there is no need to switch to a different TTY.

The script will start an X server and run your `XINITRC_PATH` script with the first argument passed from it and the second set to `nvidia` (so `./run.sh i3` will run `XINITRC_PATH i3 nvidia`).

Your X session should now be running on NVIDIA card. This can be checked with programs such as `glmark2`. After closing that session, your nvidia card should power off.

### More info
* [this blog post](https://www.ifnull.org/articles/void_optimus_nvidia_intel/) - inspiration for `install.sh`
* [nvidia-xrun](https://github.com/Witko/nvidia-xrun) - inspiration for `run.sh`
* [this void-packages issue](https://github.com/voidlinux/void-packages/issues/5863) - issue with conflicting opengl libraries
* [Void Wiki Steam article](https://wiki.voidlinux.org/Steam) - has a guide on 32bit libraries
