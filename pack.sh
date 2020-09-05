#!/bin/sh

LOG_PATH=/dev/stderr
if [ "$1" = "-q" ]; then
    LOG_PATH=/dev/null
fi

HOME_1='.xinitrc'

HOME_2='
bin/action-launcher
bin/battery-info
bin/flip-a-coin
bin/game-mode
bin/initscripts
bin/mount-smb
bin/mpc-insert
bin/notify-info
bin/screenshot
bin/steam-runtime
bin/stickywindow
bin/storage-spindown
bin/wallock'

HOME_3='Games/games.py
Games/presets.yaml
Games/winekill.sh'

HOME_4='.config/alacritty/alacritty.yml
.config/i3/config
.config/mpd/mpd.conf
.config/mpv/input.conf
.config/mpv/mpv.conf
.config/neofetch/config.conf
.config/nvim/init.vim
.config/htop/htoprc
.config/cava/config
.config/polybar/config
.config/polybar/style
.config/polybar/vars
.config/polybar/vars_clear
.config/polybar/vars_darker
.config/rofi/config.rasi
.config/rofi/default.rasi
.config/rofi/edwardium.rasi
.config/zsh/edwardium.zsh-theme
.config/ranger/commands.py
.config/ranger/rc.conf
.config/ranger/rilfe.conf
.config/ranger/scope.sh
.config/SpeedCrunch/SpeedCrunch.ini
.config/sway/config
.config/swaylock/config
.config/waybar/config
.config/waybar/style.css
.config/waybar/style.less
.config/youtube-dl/config'

OPT='nvidia/install.py
nvidia/off.sh
nvidia/run-glvnd.sh
nvidia/run.sh'

ETC='rc.local'

ETC_X11='nvidia/xorg.conf
nvidia/xorg.conf.d'

backup() {
    local from=$1
    local to=$2

    printf 'Backing up "%s" to "%s"\n' "$from" "$to"
    mkdir -p $(dirname "$to")
    cp --no-dereference --preserve=all "$from" "$to"
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

diff_backup '/home/edward' "$HOME_1"
diff_backup '/home/edward' "$HOME_2"
diff_backup '/home/edward' "$HOME_3"
diff_backup '/home/edward' "$HOME_4"

diff_backup '/opt' "$OPT"
diff_backup '/etc' "$ETC"
diff_backup '/etc/X11' "$ETC_X11"