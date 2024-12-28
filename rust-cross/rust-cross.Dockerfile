ARG BASE_IMAGE=rust
ARG BASE_OS=slim-bookworm
FROM $BASE_IMAGE:$BASE_OS

ARG BASE_OS=slim-bookworm
ARG TARGETARCH

WORKDIR /tmp/rust-cross

## BASE SETUP (toolchain + extra os packages)

ARG RUST_TOOLCHAIN=stable
RUN rustup default "$RUST_TOOLCHAIN" && rustup component add rust-src
RUN rustup target add \
	aarch64-unknown-linux-musl aarch64-unknown-linux-gnu \
	x86_64-unknown-linux-musl x86_64-unknown-linux-gnu \
	wasm32-unknown-unknown wasm32-wasip1 wasm32-wasip2

# python3 is for zig-cc script
# wget and xz are for zig and cargo-component install
# deriving images might need to install `crossbuild-essential-amd64` or `crossbuild-essential-arm64` as needed (on debian)
RUN <<EOF
	set -e

	case "$BASE_OS" in
		alpine*)
			apk update
			apk add --no-cache python3 wget xz git musl-dev
		;;
		*)
			apt-get update
			apt-get install -y --no-install-recommends python3 wget xz-utils git
			rm -rf /var/lib/apt/lists/*
		;;
	esac
EOF

## ZIG SETUP

ARG ZIG_VERSION=0.13.0
RUN --mount=type=cache,target=/tmp/rust-cross <<EOF
	set -e

	case "$TARGETARCH" in
		amd64) zigArch='x86_64' ;;
		arm64) zigArch='aarch64' ;;
		*) echo >&2 "unsupported architecture: $TARGETARCH"; exit 1 ;;
	esac
	zigName="zig-linux-${zigArch}-${ZIG_VERSION}"
	if [ ! -f "${zigName}.tar.xz" ]; then
		wget --progress=bar:force "https://ziglang.org/download/${ZIG_VERSION}/${zigName}.tar.xz"
	fi

	tar xJf "${zigName}.tar.xz"
	mv "${zigName}/lib" /usr/local/lib/zig
	mv "${zigName}/zig" /usr/local/bin/zig
	rm -r "${zigName}"
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

# https://github.com/cargo-bins/cargo-binstall/releases/download/v1.10.18/cargo-binstall-aarch64-unknown-linux-musl.tgz
ARG CARGO_BINSTALL_VERSION=v1.10.18
RUN <<EOF
	set -e

	case "$TARGETARCH" in
		amd64) binArch='x86_64-unknown-linux-musl' ;;
		arm64) binArch='aarch64-unknown-linux-musl' ;;
		*) echo >&2 "unsupported architecture: $TARGETARCH"; exit 1 ;;
	esac
	binName="cargo-binstall-${binArch}"
	if [ ! -f "${binName}.tgz" ]; then
		wget --progress=bar:force "https://github.com/cargo-bins/cargo-binstall/releases/download/${CARGO_BINSTALL_VERSION}/${binName}.tgz"
	fi

	tar xzf "${binName}.tgz"
	mv cargo-binstall /usr/local/cargo/bin/cargo-binstall
EOF

ARG CARGO_COMPONENT_VERSION=0.19.0
RUN cargo binstall --install-path /usr/local/cargo/bin cargo-component@$CARGO_COMPONENT_VERSION

## ENV

ENV CARGO_HOME=/var/cache/cargo-home
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
