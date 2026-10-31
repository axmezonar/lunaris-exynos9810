# Lunaris AOSP — Exynos 9810

Unofficial device bring-up and build automation for the **Samsung Galaxy Note 9 Exynos SM-N960F**.

| Item | Value |
|---|---|
| Device | Samsung Galaxy Note 9 Exynos |
| Model | SM-N960F |
| Codename | `crownlte` |
| SoC | Samsung Exynos 9810 |
| ROM source | [Lunaris AOSP](https://github.com/Lunaris-AOSP/android) |
| ROM branch | `16.2` |
| Device-tree base | LineageOS `lineage-23.2` generation |
| Lunch target | `lineage_crownlte-bp4a-user` |

> **Status: experimental bring-up.** The repository connects Lunaris 16.2 to the public Exynos 9810 device, kernel, vendor, and Samsung hardware sources. It has not yet been verified to compile, boot, or pass hardware testing. A successful source sync is not proof of a working ROM.

## What's included

- `local_manifests/crownlte.xml`: pinned Note 9 device tree, common tree, kernel, vendor files, and Samsung dependencies.
- `scripts/verify-device-tree.sh`: validates expected source paths and product identifiers after sync.
- `scripts/build-rom.sh`: runs the Lunaris lunch target and `m bacon`.
- `scripts/build-from-github.sh`: one-command local source sync and ROM build.
- `.github/workflows/build-rom.yml`: manual GitHub Actions build, logging, and ROM artifact upload.
- `PORT_STATUS.md`: verified baseline and remaining bring-up work.
- `RUNNER_SETUP.md`: the one-time runner prerequisite.

The Android source tree is fetched by `repo` at build time; it is not duplicated in this small configuration repository.

## Build from GitHub

Open **Actions → Build Lunaris — crownlte → Run workflow**. The workflow has an optional `clean_out` input; leave it off for incremental builds.

### Important: build runner requirement

The workflow intentionally uses a **self-hosted** Linux x86-64 runner labeled `android-builder`. GitHub's standard hosted Linux runner has only 14 GB SSD and 16 GB RAM for public repositories, which is insufficient for a full Android build. GitHub larger runners can provide 16 vCPU / 64 GB RAM / 600 GB SSD, but are only available to eligible organizations/enterprise plans and must be configured separately.

Required runner labels:
- `self-hosted`
- `linux`
- `x64`
- `android-builder`

Recommended machine:
- Ubuntu 24.04 (or compatible Linux)
- 64 GB RAM
- at least 450 GiB free SSD before sync; 1 TB recommended
- 8+ CPU threads
- Git, Git LFS, Python 3, curl, and Android build dependencies

The workflow checks memory and disk before syncing. It uses `/srv/android/lunaris-exynos9810` as its persistent build workspace.

**This is the one remaining infrastructure step outside this repository:** the runner must be installed and registered on a suitably provisioned machine. GitHub repository access does not provision compute or create the short-lived runner registration token. Until a matching runner is online, the build job will stay queued. Follow [RUNNER_SETUP.md](RUNNER_SETUP.md) or [GitHub's self-hosted runner guide](https://docs.github.com/en/actions/how-tos/manage-runners/self-hosted-runners/add-runners).

## Device source baseline

The local manifest pins these source repositories:

| Component | Repository | Branch |
|---|---|---|
| Crownlte device tree | [android_device_samsung_crownlte](https://github.com/ExyHyperBrick/android_device_samsung_crownlte) | `lineage-23.2` |
| Exynos 9810 common tree | [android_device_samsung_exynos9810-common](https://github.com/ExyHyperBrick/android_device_samsung_exynos9810-common) | `lineage-23.2` |
| Exynos 9810 kernel | [android_kernel_samsung_exynos9810](https://github.com/ExyHyperBrick/android_kernel_samsung_exynos9810) | `lineage-23.2` |
| Crownlte proprietary files | [proprietary_vendor_samsung_crownlte](https://github.com/ExyHyperBrick/proprietary_vendor_samsung_crownlte) | `lineage-23.2` |
| Common proprietary files | [proprietary_vendor_samsung_exynos9810-common](https://github.com/ExyHyperBrick/proprietary_vendor_samsung_exynos9810-common) | `lineage-23.2` |
| Samsung hardware | [android_hardware_samsung](https://github.com/LineageOS/android_hardware_samsung) | `lineage-23.2` |
| Samsung SLSI sepolicy | [android_device_samsung_slsi_sepolicy](https://github.com/LineageOS/android_device_samsung_slsi_sepolicy) | `lineage-23.2` |
| SLSI Linaro config | [android_hardware_samsung_slsi-linaro_config](https://github.com/ExyHyperBrick/android_hardware_samsung_slsi-linaro_config) | `lineage-22.2` |
| SLSI Linaro Exynos | [android_hardware_samsung_slsi-linaro_exynos](https://github.com/ExyHyperBrick/android_hardware_samsung_slsi-linaro_exynos) | `lineage-23.2` |
| SLSI Linaro graphics | [android_hardware_samsung_slsi-linaro_graphics](https://github.com/ExyHyperBrick/android_hardware_samsung_slsi-linaro_graphics) | `lineage-22.2` |

These branches are the published Exynos 9810 development baseline. They are not proof that every Android 16/Lunaris integration issue has been solved.

## One-command local build

After cloning this repository on a properly provisioned Linux build host, run:

```bash
bash scripts/build-from-github.sh
```

It installs the Repo launcher into your user bin directory if needed, checks Git LFS and host resources, syncs Lunaris plus the crownlte manifest, validates the device tree, and starts the build. The Android build host dependencies still need to be installed.

## Manual build commands

On a properly provisioned Linux build host:

```bash
mkdir -p ~/android/lunaris-crownlte
cd ~/android/lunaris-crownlte

repo init -u https://github.com/Lunaris-AOSP/android -b 16.2 --git-lfs

mkdir -p .repo/local_manifests
curl -fsSL https://raw.githubusercontent.com/axmezonar/lunaris-exynos9810/main/local_manifests/crownlte.xml \
  -o .repo/local_manifests/crownlte.xml

repo sync -c -j4 --force-sync --no-clone-bundle --no-tags

bash <(curl -fsSL https://raw.githubusercontent.com/axmezonar/lunaris-exynos9810/main/scripts/verify-device-tree.sh) "$PWD"

source build/envsetup.sh
lunch lineage_crownlte-bp4a-user
m bacon -j8
```

Expected output directory: `out/target/product/crownlte/`. Lunaris determines the exact ZIP filename.

## Device safety

- **SM-N960F / Exynos only.** Do not flash on Snapdragon Note 9 models SM-N960U/U1/W.
- Do not flash merely because compilation succeeds.
- Back up personal data, EFS, and modem-related partitions before experimental installation.
- Test boot, recovery, audio, camera, fingerprint, Wi-Fi, Bluetooth, mobile data, NFC, encryption, S Pen, and power management before calling the ROM usable.

## Credits

Lunaris AOSP, LineageOS, ExyHyperBrick, Exynos 9810 device maintainers, and contributors to the Samsung SLSI hardware projects.
