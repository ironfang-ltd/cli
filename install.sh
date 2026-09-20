#!/bin/sh
# Install the ironfang CLI: the latest release from ironfang-ltd/cli (or
# IRONFANG_VERSION=x.y.z), verified against the release's SHA-256 sums,
# into ~/.local/bin or IRONFANG_INSTALL_DIR. POSIX sh; needs curl, tar and
# sha256sum or shasum.
set -eu
repo="ironfang-ltd/cli"
os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
case "$arch" in
    x86_64|amd64) arch=amd64 ;;
    aarch64|arm64) arch=arm64 ;;
    *) echo "ironfang: no build for architecture $arch" >&2; exit 1 ;;
esac
case "$os" in
    linux|darwin) ;;
    *) echo "ironfang: this installer covers Linux and macOS; Windows builds are on the releases page" >&2; exit 1 ;;
esac
version="${IRONFANG_VERSION:-}"
if [ -z "$version" ]; then
    version=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" | sed -n 's/.*"tag_name": *"cli\/v\([^"]*\)".*/\1/p' | head -n1)
    [ -n "$version" ] || { echo "ironfang: could not determine the latest release" >&2; exit 1; }
fi
name="ironfang_${version}_${os}_${arch}"
base="https://github.com/$repo/releases/download/cli/v$version"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -fsSL --retry 3 -o "$tmp/$name.tar.gz" "$base/$name.tar.gz"
curl -fsSL --retry 3 -o "$tmp/checksums.txt" "$base/ironfang_${version}_checksums.txt"
expected=$(grep " $name.tar.gz\$" "$tmp/checksums.txt" | cut -d' ' -f1)
[ -n "$expected" ] || { echo "ironfang: $name.tar.gz is not in the release's checksums" >&2; exit 1; }
if command -v sha256sum >/dev/null 2>&1; then
    actual=$(sha256sum "$tmp/$name.tar.gz" | cut -d' ' -f1)
else
    actual=$(shasum -a 256 "$tmp/$name.tar.gz" | cut -d' ' -f1)
fi
[ "$actual" = "$expected" ] || { echo "ironfang: checksum mismatch for $name.tar.gz" >&2; exit 1; }
tar -C "$tmp" -xzf "$tmp/$name.tar.gz"
dir="${IRONFANG_INSTALL_DIR:-$HOME/.local/bin}"
mkdir -p "$dir"
install -m 0755 "$tmp/$name/ironfang" "$dir/ironfang"
echo "installed ironfang $version to $dir/ironfang"
case ":$PATH:" in *":$dir:"*) ;; *) echo "add $dir to your PATH" ;; esac
