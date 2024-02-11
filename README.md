# dotfiles

This repository contains my dotfiles, such as configuration files, initialization scripts and other convenience scripts.
Some of the scripts are written for Void linux, some for Alpine and at one point I tried Gentoo.

## Git config

Don't let git autogenerate emails for newly cloned repositories.

`git config --global user.useConfigOnly true`

And set the global default to undefined, making git prompt for credentials on first commit.

`legit config --global user.name ''; legit config --global user.email ''`

## Packages

List of packages to install on new desktop systems

- sway, swaybg, wofi
- pipewire, wireplumbler
- alacritty, nano, fish, eza
- firefox, mpv
- pass, 7zip, nextcloud
- rustup, zig, httpie, kicad
- speedcrunch, htop, ncdu
