#!/usr/bin/env bash
set -Eeuo pipefail

ANDROID_ROOT="${1:-$PWD}"
cd "$ANDROID_ROOT"

required_files=(
  "device/samsung/crownlte/AndroidProducts.mk"
  "device/samsung/crownlte/lineage_crownlte.mk"
  "device/samsung/crownlte/device.mk"
  "device/samsung/crownlte/BoardConfig.mk"
  "device/samsung/crownlte/configs/audio/mixer_paths.xml"
  "device/samsung/exynos9810-common/BoardConfigCommon.mk"
  "device/samsung/exynos9810-common/common.mk"
  "device/samsung/exynos9810-common/manifest.xml"
  "device/samsung/exynos9810-common/device_framework_matrix.xml"
  "device/samsung/exynos9810-common/compatibility_matrix.xml"
  "kernel/samsung/exynos9810/Makefile"
  "kernel/samsung/exynos9810/arch/arm64/configs/exynos9810-crownlte_defconfig"
  "kernel/samsung/exynos9810/scripts/samsung_bootimg.py"
  "vendor/samsung/crownlte/crownlte-vendor.mk"
  "vendor/samsung/crownlte/BoardConfigVendor.mk"
  "vendor/samsung/exynos9810-common/BoardConfigVendor.mk"
  "hardware/samsung/vintf/samsung_framework_compatibility_matrix.xml"
  "hardware/samsung_slsi-linaro/config/BoardConfig9810.mk"
  "hardware/samsung_slsi-linaro/config/config.mk"
  "hardware/samsung_slsi-linaro/exynos/Android.bp"
  "hardware/samsung_slsi-linaro/exynos5/Android.bp"
  "hardware/samsung_slsi-linaro/graphics/Android.bp"
  "hardware/samsung_slsi-linaro/interfaces/Android.bp"
  "hardware/samsung_slsi-linaro/openmax/Android.bp"
  "device/samsung_slsi/sepolicy/sepolicy.mk"
  "device/lineage/sepolicy/exynos/sepolicy.mk"
)

failed=0
for path in "${required_files[@]}"; do
  if [[ -f "$path" ]]; then
    printf 'OK      %s\n' "$path"
  else
    printf 'MISSING %s\n' "$path"
    failed=1
  fi
done

required_dirs=(
  "hardware/google/interfaces"
  "hardware/google/pixel"
  "hardware/samsung/aidl"
)
for path in "${required_dirs[@]}"; do
  if [[ -d "$path" ]]; then
    printf 'OK      %s/\n' "$path"
  else
    printf 'MISSING %s/\n' "$path"
    failed=1
  fi
done

PRODUCT_MK="device/samsung/crownlte/lineage_crownlte.mk"
BOARD_MK="device/samsung/crownlte/BoardConfig.mk"
COMMON_BOARD="device/samsung/exynos9810-common/BoardConfigCommon.mk"
KERNEL_CONFIG="kernel/samsung/exynos9810/arch/arm64/configs/exynos9810-crownlte_defconfig"

if [[ -f "$PRODUCT_MK" ]]; then
  grep -q '^PRODUCT_NAME := lineage_crownlte$' "$PRODUCT_MK" || {
    echo "ERROR: wrong PRODUCT_NAME in $PRODUCT_MK"
    failed=1
  }
  grep -q '^PRODUCT_DEVICE := crownlte$' "$PRODUCT_MK" || {
    echo "ERROR: wrong PRODUCT_DEVICE in $PRODUCT_MK"
    failed=1
  }
  grep -q '^PRODUCT_MODEL := SM-N960F$' "$PRODUCT_MK" || {
    echo "ERROR: product model is not SM-N960F"
    failed=1
  }
  grep -q 'vendor/lineage/config/common_full_phone.mk' "$PRODUCT_MK" || {
    echo "ERROR: Lunaris/Lineage common phone configuration is not inherited"
    failed=1
  }
  grep -q 'ro.lunaris.maintainer=AxMezonar' "$PRODUCT_MK" || {
    echo "ERROR: Lunaris maintainer metadata patch has not been applied"
    failed=1
  }
fi

if [[ -f "$BOARD_MK" ]]; then
  grep -q 'exynos9810-crownlte_defconfig' "$BOARD_MK" || {
    echo "ERROR: crownlte BoardConfig does not select the Note 9 defconfig"
    failed=1
  }
fi

if [[ -f "$COMMON_BOARD" ]]; then
  grep -q 'TARGET_KERNEL_SOURCE := kernel/samsung/exynos9810' "$COMMON_BOARD" || {
    echo "ERROR: common board config does not point to the Exynos 9810 kernel"
    failed=1
  }
  grep -q 'BOARD_CUSTOM_MKBOOTIMG :=.*samsung_bootimg.py' "$COMMON_BOARD" || {
    echo "ERROR: custom Samsung boot-image packer is not configured"
    failed=1
  }
  grep -q 'BOARD_KERNEL_IMAGE_NAME := Image.samsung' "$COMMON_BOARD" || {
    echo "ERROR: expected Samsung kernel image name is not configured"
    failed=1
  }
  grep -q 'BOARD_MKBOOTIMG_ARGS := --header_version 0' "$COMMON_BOARD" || {
    echo "ERROR: legacy Samsung boot header version 0 is not configured"
    failed=1
  }
  grep -q 'BOARD_KERNEL_PAGESIZE := 2048' "$COMMON_BOARD" || {
    echo "ERROR: expected 2048-byte Samsung boot page size is not configured"
    failed=1
  }

  if grep -Eq 'BOARD_CUSTOM_BOOTIMG|BOARD_CUSTOM_BOOTIMG_MK|BOARD_KERNEL_SEPARATED_DT|TARGET_CUSTOM_DTBTOOL' "$COMMON_BOARD"; then
    echo "ERROR: obsolete boot-image/DTB flags conflict with samsung_bootimg.py"
    failed=1
  fi
fi

if [[ -f "$KERNEL_CONFIG" ]]; then
  grep -q '^CONFIG_SOC_EXYNOS9810=y$' "$KERNEL_CONFIG" || {
    echo "ERROR: kernel defconfig does not enable Exynos 9810"
    failed=1
  }
  grep -q '^CONFIG_DTS_9810_CROWN=y$' "$KERNEL_CONFIG" || {
    echo "ERROR: kernel defconfig does not enable the crownlte device tree"
    failed=1
  }
fi

MANIFEST=".repo/local_manifests/crownlte.xml"
if [[ ! -f "$MANIFEST" ]]; then
  echo "MISSING $MANIFEST"
  failed=1
else
  python3 - "$MANIFEST" <<'PY' || failed=1
import sys
import xml.etree.ElementTree as ET

manifest_path = sys.argv[1]
root = ET.parse(manifest_path).getroot()
remotes = {node.attrib["name"] for node in root.findall("remote")}
projects = root.findall("project")
paths = [node.attrib["path"] for node in projects]

if len(paths) != len(set(paths)):
    raise SystemExit("ERROR: duplicate project path in crownlte local manifest")

for project in projects:
    remote = project.attrib.get("remote")
    if remote not in remotes:
        raise SystemExit(
            f"ERROR: {project.attrib.get('path')} references undefined remote {remote!r}"
        )
    if not project.attrib.get("revision"):
        raise SystemExit(
            f"ERROR: {project.attrib.get('path')} is not pinned to a revision"
        )

required = {
    "device/samsung/crownlte",
    "device/samsung/exynos9810-common",
    "kernel/samsung/exynos9810",
    "vendor/samsung/crownlte",
    "vendor/samsung/exynos9810-common",
    "hardware/samsung_slsi-linaro/config",
    "hardware/samsung_slsi-linaro/exynos",
    "hardware/samsung_slsi-linaro/exynos5",
    "hardware/samsung_slsi-linaro/graphics",
    "hardware/samsung_slsi-linaro/interfaces",
    "hardware/samsung_slsi-linaro/openmax",
}
missing = sorted(required.difference(paths))
if missing:
    raise SystemExit("ERROR: local manifest is missing required projects: " + ", ".join(missing))

print(f"OK      local manifest ({len(projects)} unique pinned projects)")
PY
fi

if [[ "$failed" -ne 0 ]]; then
  echo "Device source validation failed; refusing to compile." >&2
  exit 1
fi

echo
echo "crownlte source and manifest checks passed."
echo "This is a static preflight only; it does not prove compilation or hardware compatibility."
