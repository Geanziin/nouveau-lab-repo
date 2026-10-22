#!/usr/bin/env bash
set -euo pipefail

if [[ "$EUID" -ne 0 ]]; then
    echo 'Run with sudo: sudo bash install.sh'
    exit 1
fi

python3 - <<'PY'
import datetime, pathlib, re, shutil
path = pathlib.Path('/etc/pacman.conf')
original = path.read_text()
sections = re.split(r'(?m)(?=^\s*\[[^\]\n]+\]\s*$)', original)
kept = []
for section in sections:
    match = re.match(r'\s*\[([^\]]+)\]', section)
    if match and match[1] in ('nvgd', 'nvgd-dkms', 'nouveau-lab'):
        continue
    kept.append(section)
block = ('[nvgd]\n'
         'SigLevel = Optional TrustAll\n'
         'Server = https://geanziin.github.io/nvgd-repo/$arch\n'
         '\n')
# Put nvgd before every other repository, but after [options].
index = next((i for i, section in enumerate(kept)
              if re.match(r'\s*\[(?!options\])[^\]]+\]', section)), len(kept))
kept.insert(index, block)
updated = ''.join(kept)
if updated != original:
    backup = path.with_name('pacman.conf.nvgd-' + datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f'))
    shutil.copy2(path, backup)
    path.write_text(updated)
    print('Backup:', backup)
print('Repository configured: [nvgd] -> https://geanziin.github.io/nvgd-repo/$arch')
PY

if [[ "${1:-}" == --configure-only ]]; then
    exit 0
fi

# Full upgrade avoids mixing Arch repository snapshots.
pacman -Syu --needed nvgd/nvgd-dkms nvgd/mesa-git nvgd/lib32-mesa-git \
    nvgd/gpu-screen-recorder-git nvgd/gpu-screen-recorder-ui-git \
    nvgd/gpu-screen-recorder-notification-git

echo 'Installation complete. Reboot after changing the kernel module.'
