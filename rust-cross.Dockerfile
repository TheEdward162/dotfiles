FROM rust:1.75-slim-bookworm

WORKDIR /tmp/rust-cross

# Add any needed toolchains here
RUN rustup target add \
	aarch64-unknown-linux-musl aarch64-unknown-linux-gnu \
	x86_64-unknown-linux-musl x86_64-unknown-linux-gnu \
	wasm32-wasi

# python3 is for zig-cc script
# wget and xz-utils are for zig install
# deriving images might need to install `crossbuild-essential-amd64` or `crossbuild-essential-arm64` as needed
RUN <<EOF
	set -e
	apt-get update
	apt-get install -y --no-install-recommends python3 wget xz-utils
	rm -rf /var/lib/apt/lists/*
EOF

# we cache the download in /tmp cache mount, when running this locally it saves time downloading the zig tar
ARG ZIG_VERSION=0.11.0
RUN --mount=type=cache,target=/tmp/rust-cross <<EOF
	set -e
	dpkgArch="$(dpkg --print-architecture)"
	case "${dpkgArch##*-}" in
		amd64) zigArch='x86_64' ;;
		arm64) zigArch='aarch64' ;;
		*) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;;
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

ENV CARGO_HOME=/var/cache/cargo-home
ENV CARGO_TARGET_DIR=/var/cache/cargo-target

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

# use zig as CC for cross compilation as well, that way we don't need cross-compilation gccs
ENV CC_x86_64_unknown_linux_musl=zig-x86_64-linux-musl
ENV CC_x86_64_unknown_linux_gnu=zig-x86_64-linux-gnu
ENV CC_aarch64_unknown_linux_musl=zig-aarch64-linux-musl
ENV CC_aarch64_unknown_linux_gnu=zig-aarch64-linux-gnu
