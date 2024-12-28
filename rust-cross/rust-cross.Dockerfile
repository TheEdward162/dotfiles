ARG BASE_IMAGE=debian
ARG BASE_TAG=bookworm-slim
FROM $BASE_IMAGE:$BASE_TAG

LABEL org.opencontainers.image.source=https://github.com/TheEdward162/dotfiles

ARG BASE_IMAGE=debian
ARG TARGETARCH

WORKDIR /tmp/rust-cross

## OS SETUP
ARG RUSTUP_VERSION=1.27.1
ARG RUST_TOOLCHAIN=stable

ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH

# python3 is for zig-cc script
# wget and xz are for downloading extra binaries (zig, cargo-binstall, cargo-component)
# deriving images might need to install `crossbuild-essential-amd64` or `crossbuild-essential-arm64` as needed (on debian)
RUN --mount=type=cache,target=/tmp/rust-cross <<EOF
	set -e

	case "$BASE_IMAGE" in
		alpine)
			libc_flavor=musl
			apk update
			apk add --no-cache ca-certificates binutils musl-dev python3 wget xz git
		;;
		debian)
			libc_flavor=gnu
			apt-get update
			apt-get install -y --no-install-recommends ca-certificates binutils python3 wget xz-utils git
			rm -rf /var/lib/apt/lists/*
		;;
	esac

	case "$TARGETARCH" in
		amd64) rust_arch="x86_64-unknown-linux-$libc_flavor" ;;
		arm64) rust_arch="aarch64-unknown-linux-$libc_flavor" ;;
		*) echo >&2 "unsupported architecture: $TARGETARCH"; exit 1 ;;
	esac
	rustup_name="rustup-init-$rust_arch-$RUSTUP_VERSION"
	if [ ! -f "$rustup_name" ]; then
		wget --progress=dot:mega -O $rustup_name "https://static.rust-lang.org/rustup/archive/$RUSTUP_VERSION/$rust_arch/rustup-init"
		chmod +x $rustup_name
	fi

	./$rustup_name -y --no-modify-path --profile minimal --default-toolchain $RUST_TOOLCHAIN --default-host $rust_arch
	chmod -R a+w $RUSTUP_HOME $CARGO_HOME
EOF

## RUST SETUP

RUN rustup component add rust-src && rustup target add \
	aarch64-unknown-linux-musl aarch64-unknown-linux-gnu \
	x86_64-unknown-linux-musl x86_64-unknown-linux-gnu \
	wasm32-unknown-unknown wasm32-wasip1 wasm32-wasip2

## ZIG SETUP
ARG ZIG_VERSION=0.13.0

RUN --mount=type=cache,target=/tmp/rust-cross <<EOF
	set -e

	case "$TARGETARCH" in
		amd64) zig_arch='x86_64' ;;
		arm64) zig_arch='aarch64' ;;
		*) echo >&2 "unsupported architecture: $TARGETARCH"; exit 1 ;;
	esac
	zig_name="zig-linux-$zig_arch-$ZIG_VERSION"
	if [ ! -f "$zig_name.tar.xz" ]; then
		wget --progress=dot:mega "https://ziglang.org/download/$ZIG_VERSION/$zig_name.tar.xz"
	fi

	tar xJf "$zig_name.tar.xz"
	mv "$zig_name/lib" /usr/local/lib/zig
	mv "$zig_name/zig" /usr/local/bin/zig
	rm -r "$zig_name"
EOF

COPY bin/zig-cc /usr/local/bin/zig-cc
RUN <<EOF
	set -e
	ln -s /usr/local/bin/zig-cc /usr/local/bin/zig-aarch64-linux-gnu
	ln -s /usr/local/bin/zig-cc /usr/local/bin/zig-aarch64-linux-musl
	ln -s /usr/local/bin/zig-cc /usr/local/bin/zig-x86_64-linux-gnu
	ln -s /usr/local/bin/zig-cc /usr/local/bin/zig-x86_64-linux-musl

	mkdir /.cargo
	cat <<EOF2 >/.cargo/config.toml
[target.x86_64-unknown-linux-musl]
linker = "zig-x86_64-linux-musl"
[target.aarch64-unknown-linux-musl]
linker = "zig-aarch64-linux-musl"

[target.x86_64-unknown-linux-gnu]
linker = "zig-x86_64-linux-gnu"
[target.aarch64-unknown-linux-gnu]
linker = "zig-aarch64-linux-gnu"
EOF2
EOF

## CARGO SUBCOMMANDS
ARG CARGO_BINSTALL_VERSION=v1.10.18
ARG CARGO_COMPONENT_VERSION=0.19.0

# https://github.com/cargo-bins/cargo-binstall/releases/download/v1.10.18/cargo-binstall-aarch64-unknown-linux-musl.tgz
RUN --mount=type=cache,target=/tmp/rust-cross <<EOF
	set -e

	case "$TARGETARCH" in
		amd64) bin_arch='x86_64-unknown-linux-musl' ;;
		arm64) bin_arch='aarch64-unknown-linux-musl' ;;
		*) echo >&2 "unsupported architecture: $TARGETARCH"; exit 1 ;;
	esac
	bin_name="cargo-binstall-$bin_arch-$CARGO_BINSTALL_VERSION"
	if [ ! -f "$bin_name.tgz" ]; then
		wget --progress=dot:mega -O $bin_name.tgz "https://github.com/cargo-bins/cargo-binstall/releases/download/$CARGO_BINSTALL_VERSION/cargo-binstall-$bin_arch.tgz"
	fi

	tar xzf "$bin_name.tgz"
	mv cargo-binstall $CARGO_HOME/bin/cargo-binstall
EOF

RUN cargo binstall cargo-component@$CARGO_COMPONENT_VERSION

## ENV

ENV CARGO_TARGET_DIR=/var/cache/cargo-target

# use zig as CC for cross compilation as well, that way we don't need cross-compilation gccs
ENV CC_x86_64_unknown_linux_musl=zig-x86_64-linux-musl
ENV CC_x86_64_unknown_linux_gnu=zig-x86_64-linux-gnu
ENV CC_aarch64_unknown_linux_musl=zig-aarch64-linux-musl
ENV CC_aarch64_unknown_linux_gnu=zig-aarch64-linux-gnu

# if using git dependencies over https this will support access tokens supplied with --mount=type=secret,id=git-password
RUN <<EOF
	cat <<EOF2 >$HOME/.gitconfig
[credential]
helper = "!f() { echo username=git; echo \"password=\$(cat /run/secrets/git-password)\"; }; f"
EOF2
EOF
