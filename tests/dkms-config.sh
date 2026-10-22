#!/usr/bin/env bash
set -euo pipefail
config_dir="${1:-$(dirname "$0")/../packaging/nvgd-dkms}"
kernel_source_dir=/test/kernel/build
# shellcheck source=/dev/null
source "$config_dir/dkms.conf"
[[ "$AUTOINSTALL" == yes && "$BUILD_EXCLUSIVE_KERNEL_MIN" == 7.2 ]]
for kernel in 7.2.11-1-cachyos 7.3.0-3-cachyos 7.10.0-test 8.0.0-test; do
    [[ "$kernel" =~ $BUILD_EXCLUSIVE_KERNEL ]]
done
for kernel in 6.18.55-2-cachyos-lts 6.6.1-test; do
    [[ ! "$kernel" =~ $BUILD_EXCLUSIVE_KERNEL ]]
done

# Simulate modinfo for exactly the kernel mkinitcpio is currently building.
# No module/firmware should be forced into images without a built nvgd.
modinfo() {
    [[ "$*" == "-k $KERNELVERSION -n nvgd" && "$module_exists" == yes ]]
}
for KERNELVERSION in 7.2.11-1-cachyos 7.3.0-3-cachyos 8.0.0-test; do
    for module_exists in yes no; do
        MODULES=()
        FILES=()
        # shellcheck source=/dev/null
        source "$config_dir/mkinitcpio-nvgd.conf"
        if [[ "$module_exists" == yes ]]; then
            [[ "${MODULES[*]}" == nvgd && "${#FILES[@]}" == 2 ]]
        else
            [[ "${#MODULES[@]}" == 0 && "${#FILES[@]}" == 0 ]]
        fi
    done
done
echo 'PASS: kernel update matching and per-kernel initramfs inclusion'
