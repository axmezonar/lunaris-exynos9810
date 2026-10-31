#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_ROOT="${ANDROID_ROOT:-$PWD}"
JOBS="${BUILD_JOBS:-8}"

cd "$ANDROID_ROOT"

if [[ ! -f build/envsetup.sh ]]; then
  echo "Android source tree not found at $ANDROID_ROOT" >&2
  exit 1
fi

bash "$ROOT/scripts/verify-device-tree.sh" "$ANDROID_ROOT"

source build/envsetup.sh
lunch lineage_crownlte-bp4a-userdebug
m bacon -j"$JOBS"

OUT="$ANDROID_ROOT/out/target/product/crownlte"
shopt -s nullglob
zips=("$OUT"/*.zip)

if (( ${#zips[@]} == 0 )); then
  echo "Build command completed but no ROM ZIP was found in $OUT" >&2
  exit 1
fi

printf 'ROM output(s):\n'
printf '  %s\n' "${zips[@]}"
