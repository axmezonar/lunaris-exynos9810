#!/usr/bin/env bash
set -Eeuo pipefail

ANDROID_ROOT="${1:-$PWD}"
PRODUCT_MK="$ANDROID_ROOT/device/samsung/crownlte/lineage_crownlte.mk"

if [[ ! -f "$PRODUCT_MK" ]]; then
  echo "Missing Note 9 product file: $PRODUCT_MK" >&2
  exit 1
fi

grep -q '^PRODUCT_NAME := lineage_crownlte$' "$PRODUCT_MK" || {
  echo "Unexpected crownlte product name; refusing to patch the wrong product." >&2
  exit 1
}

grep -q '^PRODUCT_DEVICE := crownlte$' "$PRODUCT_MK" || {
  echo "Unexpected crownlte device codename; refusing to patch the wrong product." >&2
  exit 1
}

if grep -q 'ro\.lunaris\.maintainer=' "$PRODUCT_MK"; then
  if ! grep -q 'ro\.lunaris\.maintainer=AxMezonar' "$PRODUCT_MK"; then
    echo "A different Lunaris maintainer is already set in $PRODUCT_MK." >&2
    echo "Review it manually rather than silently replacing it." >&2
    exit 1
  fi
else
  cat >> "$PRODUCT_MK" <<'EOF'

# Lunaris device maintainer
PRODUCT_PRODUCT_PROPERTIES += \
    ro.lunaris.maintainer=AxMezonar
EOF
fi

echo "Lunaris maintainer property is configured for AxMezonar."
