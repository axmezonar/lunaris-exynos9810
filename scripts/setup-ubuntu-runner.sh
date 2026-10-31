#!/usr/bin/env bash
set -Eeuo pipefail

if [[ ! -r /etc/os-release ]]; then
  echo "Cannot identify the host OS." >&2
  exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release

if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "24.04" ]]; then
  echo "This runner bootstrap is intended for Ubuntu 24.04; found ${PRETTY_NAME:-unknown}." >&2
  exit 1
fi

if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "Android Exynos build runner must be Linux x86_64." >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required to install the host build packages." >&2
  exit 1
fi

mem_kb="$(awk '/MemTotal:/ {print $2}' /proc/meminfo)"
mem_gib="$((mem_kb / 1024 / 1024))"
if (( mem_gib < 58 )); then
  echo "This host has ${mem_gib} GiB RAM. Use at least 64 GiB." >&2
  exit 1
fi

BUILD_ROOT="/srv/android"
sudo mkdir -p "$BUILD_ROOT"
free_bytes="$(df -PB1 "$BUILD_ROOT" | awk 'END {print $4}')"
free_gib="$((free_bytes / 1024 / 1024 / 1024))"
if (( free_gib < 450 )); then
  echo "Only ${free_gib} GiB is free under $BUILD_ROOT. At least 450 GiB is required." >&2
  exit 1
fi

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  git-core git-lfs gnupg flex bison build-essential \
  zip unzip curl wget rsync bc file xz-utils lz4 \
  zlib1g-dev libc6-dev-i386 lib32z1-dev \
  x11proto-core-dev libx11-dev libgl1-mesa-dev \
  libxml2-utils xsltproc fontconfig \
  libssl-dev libelf-dev libncurses-dev python3 python-is-python3

git lfs install
sudo chown -R "$USER":"$USER" "$BUILD_ROOT"

echo
echo "Android build dependencies installed."
echo "Build workspace: $BUILD_ROOT"
echo "Next: register a self-hosted GitHub Actions runner for axmezonar/lunaris-exynos9810"
echo "and add the custom label: android-builder"
