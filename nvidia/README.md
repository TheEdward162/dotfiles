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

First thing to do is to edit the `$PREFIX` variable in the `install.sh` script. That way you can control where the nvidia libraries will be installed. Also if you are not installing/using 32bit libraries, delete them from the `install.sh` script from line `xbps-install -fy libGL libEGL libGL-32bit libEGL-32bit` (make it `xbps-install -fy libGL libEGL`).

Next step is to obtain the `NVIDIA-Linux-x86_64-XXX.XX.run` binary from nvidia driver download page. Then run `sudo ./install.sh ./NVIDIA-Linux-x86_64-XXX.XX.run` and basically say yes to everything. This will mess up your mesa installation, but the script should fix that later.

If the script runs successfully, you should now have a working mesa installation and a separate nvidia instalation in `$PREFIX` (default in `/opt/nvidia`).

*Note: This could probably be done with chroot to avoid having to reinstall system libraries, but I couldn't get it to work.*

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
After you have installed the nvidia libraries, set up your xorg config files and changed the `run.sh` script to point at them, all that's left is to run it. Switch to a TTY that doesn't have X session running on it. You can do this using `Ctrl+Alt+FX` keys. If you are currently in console mode, there is no need to switch to a different TTY.

The script will start an X server and run your `XINITRC_PATH` script with the first argument passed from it and the second set to `nvidia` so `run.sh i3` will run `XINITRC_PATH i3 nvidia`.

Your X session should now be running on NVIDIA card. This can be checked with programs such as `glmark2`. After closing that session, your nvidia card should power off.
