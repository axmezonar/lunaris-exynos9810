# Exynos 9810 / Lunaris 16.2 port status

## Verified source facts

- Target device: Galaxy Note 9 Exynos SM-N960F, codename `crownlte`.
- Device tree: `ExyHyperBrick/android_device_samsung_crownlte`, branch `lineage-23.2`.
- Common tree: `ExyHyperBrick/android_device_samsung_exynos9810-common`, branch `lineage-23.2`.
- Kernel: `ExyHyperBrick/android_kernel_samsung_exynos9810`, branch `lineage-23.2`.
- Device and common vendor repositories publish `lineage-23.2` branches.
- Lunaris source manifest is on branch `16.2`; its build instructions use the `bp4a` release suffix and `m bacon`.

## Not yet verified

No compile has been executed from this repository. Therefore the following remain unknown:

- Whether the selected LineageOS 23.2 device components compile unmodified against Lunaris 16.2.
- Whether HIDL/AIDL compatibility and vendor interface versions match.
- Whether all Soong namespaces, product makefiles, and dependencies resolve in a clean Lunaris sync.
- Whether the generated boot/recovery images are accepted by the SM-N960F bootloader and recovery.
- Whether the ROM boots or has working radio, audio, camera, fingerprint, NFC, Bluetooth, Wi-Fi, encryption, S Pen, and power management.

## Bring-up sequence

1. Sync the pinned source manifest.
2. Run `scripts/verify-device-tree.sh`.
3. Attempt `lunch lineage_crownlte-bp4a-user`.
4. Resolve real Soong, Make, SELinux, VINTF, and kernel integration errors from the build log.
5. Produce the ROM ZIP.
6. Test on an SM-N960F with complete EFS/modem and user-data backups.
7. Only label a build usable after hardware and stability tests.

Do not describe this port as booting or daily-driver-ready until those tests have been performed.
