FROM rust:1.72-bookworm

WORKDIR tmp

# Add any needed toolchains here
RUN rustup target add aarch64-unknown-linux-musl aarch64-unknown-linux-gnu x86_64-unknown-linux-gnu x86_64-unknown-linux-musl

ARG ZIG_VERSION=0.11.0
RUN <<EOF
	set -e
	dpkgArch="$(dpkg --print-architecture)"
	case "${dpkgArch##*-}" in
        amd64) zigArch='x86_64' ;;
        arm64) zigArch='aarch64' ;;
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;;
    esac
	zigName="zig-linux-${zigArch}-${ZIG_VERSION}"
	wget --progress=bar:force "https://ziglang.org/download/0.11.0/${zigName}.tar.xz"
	tar xJf "${zigName}.tar.xz"
	mv "${zigName}/lib" /usr/local/lib/zig
	mv "${zigName}/zig" /usr/local/bin/zig
	rm -r "${zigName}.tar.xz" "$zigName"
EOF

COPY bin/zig-cc /usr/local/bin/zig-cc
COPY .config/cargo $CARGO_HOME/config
RUN <<EOF
	set -e
	ln -s /usr/local/bin/zig-cc /usr/local/bin/zig-aarch64-linux-gnu
	ln -s /usr/local/bin/zig-cc /usr/local/bin/zig-aarch64-linux-musl
	ln -s /usr/local/bin/zig-cc /usr/local/bin/zig-x86_64-linux-gnu
	ln -s /usr/local/bin/zig-cc /usr/local/bin/zig-x86_64-linux-musl
EOF
