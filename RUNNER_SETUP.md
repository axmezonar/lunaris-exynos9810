# One-time build runner setup

The repository and workflow are committed, but the GitHub Actions workflow requires a Linux build host with the `android-builder` runner label.

## Required host

- Linux x86-64; Ubuntu 24.04 recommended
- 64 GB RAM
- At least 450 GiB free disk before source sync; 1 TB SSD recommended
- 8+ CPU threads
- Git LFS, Python 3, curl, and the Android build dependencies

GitHub standard hosted runners do not have enough local SSD or memory for a full Android source build. GitHub larger runners with 16 vCPU / 64 GB RAM / 600 GB SSD are an option only where the GitHub account/organization plan has access to larger runners and they are configured. See [GitHub larger runners](https://docs.github.com/en/actions/reference/runners/larger-runners).

## Register the runner

In this repository:

1. Open **Settings → Actions → Runners**.
2. Select **New self-hosted runner** and choose Linux x64.
3. Follow GitHub's displayed download and configuration commands.
4. When prompted for additional labels, add `android-builder`.
5. Install the runner as a service and keep it online.

The registration token is short-lived and must be obtained from the repository's Settings page. It is intentionally not stored in source control.

## Build

Once the runner is online, open **Actions → Build Lunaris — crownlte → Run workflow**. Leave `clean_out` disabled for incremental builds. Enable it only when a clean Android output directory is needed.

A successful build uploads the generated ZIP as a workflow artifact for 14 days. Failed builds upload their log when one is available.

The workflow does not flash the ROM to a phone and does not claim that a compile is a successful boot test.
