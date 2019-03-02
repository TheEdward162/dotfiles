## NVIDIA hacks for NVIDIA Optimus
<hr>

### Dependencies
* `nvidia-dkms` package for the kernel modules.
* `libGL libEGL` mesa drivers (optionally also `libGL-32bit libEGL-32bit`).
* `bbswitch` must **NOT** be installed/loaded, or the run script will hang.
* `xrandr xorg`
* any WM

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

This script also creates a fake xbps package database in `fakeroot/var/db/xbps/pkgdb-0.38.plist` to trick xbps into thinking all the required packages except for the nvidia driver ones are actually in the fakeroot. This is a *hack*, but it should work as long as the required packages are actually installed on your system.

After running the python script, you will be prompted by `xbps-install` for confirmation, but all other `xbps-install` output will be only printed after the script ends.

### xorg
Now you need to create a valid xorg configuration somewhere in `/etc/X11` (for example `/etc/X11/nvidia`). Copy `xorg.conf` and `xorg.conf.d` there. You also need to prepare your `xinitrc` somewhere and change the `run.sh` script to point to them. Specifically the lines:
```
XINITRC_PATH=$HOME/.xinitrc
CONFIG_PATH=nvidia/xorg.conf
CONFIGDIR_PATH=nvidia/xorg.conf.d
```
`XINITRC_PATH` expects an absolute path, `CONFIG_PATH` and `CONFIGDIR_PATH` need a path relative to `/etc/X11`.
Your `xinitrc` needs to contain at least these two lines:
```
xrandr --setprovideroutputsource modesetting NVIDIA-0
xrandr --auto
```

### run.sh
If you aren't installing/using 32bit libraries, change `LIBRARY_PATHS="/opt/nvidia/fakeroot/lib /opt/nvidia/fakeroot/lib32"` to `LIBRARY_PATHS="/opt/nvidia/fakeroot/lib"`.

After you have installed the nvidia libraries, set up your xorg config files and changed the `run.sh` script to point at them, all that's left is to run it. Switch to a TTY that doesn't have X session running on it. You can do this using `Ctrl+Alt+FX` keys. If you are currently in console mode, there is no need to switch to a different TTY.

The script will start an X server and run your `XINITRC_PATH` script with the first argument passed from it and the second set to `nvidia` so `run.sh i3` will run `XINITRC_PATH i3 nvidia`.

Your X session should now be running on NVIDIA card. This can be checked with programs such as `glmark2`. After closing that session, your nvidia card should power off.
