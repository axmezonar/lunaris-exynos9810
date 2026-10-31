#!/usr/bin/env bash
set -Eeuo pipefail

if (( $# < 1 || $# > 3 )); then
  echo "Usage: bash scripts/join-rom-parts.sh ROM_FILENAME.zip [DOWNLOAD_DIR] [OUTPUT_FILE]" >&2
  exit 2
fi

ROM_NAME="$1"
DOWNLOAD_DIR="${2:-$PWD}"
OUTPUT_FILE="${3:-$ROM_NAME}"

if [[ "$ROM_NAME" == */* || "$ROM_NAME" != *.zip ]]; then
  echo "ROM_FILENAME must be a ZIP basename, not a path." >&2
  exit 2
fi

CHECKSUM_FILE="$DOWNLOAD_DIR/SHA256SUMS"
if [[ ! -f "$CHECKSUM_FILE" ]]; then
  echo "Missing $CHECKSUM_FILE. Download SHA256SUMS from the same GitHub Release." >&2
  exit 1
fi

EXPECTED="$(awk -v name="$ROM_NAME" '$2 == name { print $1; exit }' "$CHECKSUM_FILE")"
if [[ -z "$EXPECTED" ]]; then
  echo "No SHA-256 entry for $ROM_NAME in $CHECKSUM_FILE." >&2
  exit 1
fi

if [[ -f "$DOWNLOAD_DIR/$ROM_NAME" ]]; then
  if [[ "$DOWNLOAD_DIR/$ROM_NAME" != "$OUTPUT_FILE" ]]; then
    cp -- "$DOWNLOAD_DIR/$ROM_NAME" "$OUTPUT_FILE"
  fi
else
  shopt -s nullglob
  PARTS=("$DOWNLOAD_DIR/$ROM_NAME".part-*)
  if (( ${#PARTS[@]} == 0 )); then
    echo "No ROM ZIP or split parts found for $ROM_NAME in $DOWNLOAD_DIR." >&2
    exit 1
  fi

  printf 'Joining %d ROM parts...\n' "${#PARTS[@]}"
  cat -- "${PARTS[@]}" > "$OUTPUT_FILE"
fi

ACTUAL="$(sha256sum "$OUTPUT_FILE" | awk '{print $1}')"
if [[ "$ACTUAL" != "$EXPECTED" ]]; then
  rm -f -- "$OUTPUT_FILE"
  echo "SHA-256 verification FAILED. The output file was removed." >&2
  echo "Expected: $EXPECTED" >&2
  echo "Actual:   $ACTUAL" >&2
  exit 1
fi

echo "ROM assembled and SHA-256 verified:"
echo "  $OUTPUT_FILE"
echo "  $ACTUAL"
