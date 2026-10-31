#!/usr/bin/env bash
set -Eeuo pipefail

ANDROID_ROOT="${1:-$PWD}"
cd "$ANDROID_ROOT"

required=(
  "device/samsung/crownlte/AndroidProducts.mk"
  "device/samsung/crownlte/lineage_crownlte.mk"
  "device/samsung/crownlte/device.mk"
  "device/samsung/crownlte/BoardConfig.mk"
  "device/samsung/exynos9810-common/BoardConfigCommon.mk"
  "device/samsung/exynos9810-common/common.mk"
  "kernel/samsung/exynos9810"
  "vendor/samsung/crownlte/crownlte-vendor.mk"
  "vendor/samsung/exynos9810-common"
  "hardware/samsung/vintf"
  "hardware/samsung_slsi-linaro/config/BoardConfig9810.mk"
  "hardware/samsung_slsi-linaro/exynos"
  "hardware/samsung_slsi-linaro/graphics"
  "device/samsung_slsi/sepolicy"
  "device/lineage/sepolicy/exynos/sepolicy.mk"
)

failed=0
for path in "${required[@]}"; do
  if [[ -e "$path" ]]; then
    printf 'OK      %s\n' "$path"
  else
    printf 'MISSING %s\n' "$path"
    failed=1
  fi
done

if [[ -f device/samsung/crownlte/BoardConfig.mk ]] &&
   ! grep -q 'exynos9810-crownlte_defconfig' device/samsung/crownlte/BoardConfig.mk; then
  echo "ERROR: crownlte BoardConfig does not select exynos9810-crownlte_defconfig"
  failed=1
fi

if [[ -f device/samsung/crownlte/lineage_crownlte.mk ]] &&
   ! grep -q 'PRODUCT_NAME := lineage_crownlte' device/samsung/crownlte/lineage_crownlte.mk; then
  echo "ERROR: expected PRODUCT_NAME := lineage_crownlte"
  failed=1
fi

if [[ "$failed" -ne 0 ]]; then
  echo "Device source validation failed. Fix the manifest/tree mismatch before building." >&2
  exit 1
fi

echo "crownlte source presence checks passed."
echo "This check does not prove Android 16 compilation or hardware compatibility."
