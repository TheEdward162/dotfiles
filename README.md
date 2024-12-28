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

- musl-dev, perl

## rust-cross

A Big Rust™️ image that contains everything needed for cross-compiling Rust both to different OSes and WASM (wasm32, wasip1, cargo-component, wasip2). It's also a compilation of random tibits of Cargo/Rust configuration that may or may not work when compiling for different targets.

To build locally run:
```sh
docker build --tag ghcr.io/theedward162/rust-cross:1.83-alpine-3.21 -f rust-cross/rust-cross.Dockerfile . --build-arg BASE_IMAGE=alpine --build-arg BASE_TAG=3.21 --build-arg RUST_TOOLCHAIN=1.83
docker build --tag ghcr.io/theedward162/rust-cross:1.83-debian-trixie-slim -f rust-cross/rust-cross.Dockerfile . --build-arg BASE_IMAGE=debian --build-arg BASE_TAG=trixie-slim --build-arg RUST_TOOLCHAIN=1.83
```
