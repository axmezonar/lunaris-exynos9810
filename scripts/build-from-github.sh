#!/usr/bin/env bash
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_ROOT="${ANDROID_ROOT:-$HOME/android/lunaris-exynos9810}"
SYNC_JOBS="${REPO_SYNC_JOBS:-4}"
BUILD_JOBS="${BUILD_JOBS:-8}"

if ! command -v git >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
  echo "git and curl are required. Install the Android build host dependencies first." >&2
  exit 1
fi

mkdir -p "$HOME/bin"
if ! command -v repo >/dev/null 2>&1; then
  curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "$HOME/bin/repo"
  chmod 0755 "$HOME/bin/repo"
  export PATH="$HOME/bin:$PATH"
fi

if ! git lfs version >/dev/null 2>&1; then
  echo "Git LFS is required. Install git-lfs first." >&2
  exit 1
fi
git lfs install

mkdir -p "$ANDROID_ROOT"
mem_kb="$(awk '/MemTotal:/ {print $2}' /proc/meminfo)"
mem_gib="$((mem_kb / 1024 / 1024))"
free_bytes="$(df -PB1 "$ANDROID_ROOT" | awk 'END {print $4}')"
free_gib="$((free_bytes / 1024 / 1024 / 1024))"

echo "Build directory: $ANDROID_ROOT"
echo "Available RAM:   ${mem_gib} GiB"
echo "Available disk:  ${free_gib} GiB"

if (( mem_gib < 58 )); then
  echo "At least 58 GiB RAM is required by this build profile; 64 GiB is recommended." >&2
  exit 1
fi

if (( free_gib < 450 )); then
  echo "At least 450 GiB free disk space is required before syncing." >&2
  exit 1
fi

cd "$ANDROID_ROOT"

repo init \
  -u https://github.com/Lunaris-AOSP/android \
  -b 16.2 \
  --git-lfs

mkdir -p .repo/local_manifests
install -m 0644 \
  "$REPO_ROOT/local_manifests/crownlte.xml" \
  .repo/local_manifests/crownlte.xml

repo sync -c \
  -j"$SYNC_JOBS" \
  --force-sync \
  --no-clone-bundle \
  --no-tags

ANDROID_ROOT="$ANDROID_ROOT" BUILD_JOBS="$BUILD_JOBS" \
  bash "$REPO_ROOT/scripts/build-rom.sh"
