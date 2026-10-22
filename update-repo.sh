#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="${LAB_DIR:-/home/gean/Documents/nouveau-lab}"
export REPO_DIR LAB_DIR

# Read package metadata: glob ordering is not Arch version ordering.
python3 - <<'PY'
import os, pathlib, shutil, subprocess
root = pathlib.Path(os.environ['REPO_DIR']) / 'x86_64'
root.mkdir(exist_ok=True)
lab = pathlib.Path(os.environ['LAB_DIR']) / 'packaging'
packages = {
    'mesa-git': 'mesa-git-lab',
    'lib32-mesa-git': 'lib32-mesa-git',
    'nvgd-dkms': 'nvgd-dkms',
    'gpu-screen-recorder-git': 'gpu-screen-recorder-git',
    'gpu-screen-recorder-ui-git': 'gpu-screen-recorder-ui-git',
    'gpu-screen-recorder-notification-git': 'gpu-screen-recorder-notification-git',
}
selected = []
for name, directory in packages.items():
    best = None
    for path in list((lab / directory).glob('*.pkg.tar.zst')) + list(root.glob('*.pkg.tar.zst')):
        fields = subprocess.check_output(['pacman', '-Qp', '--', str(path)], text=True).split()
        if fields[0] != name:
            continue
        version = fields[1]
        if best is None or int(subprocess.check_output(['vercmp', version, best[0]], text=True)) > 0:
            best = (version, path)
    if best is None:
        raise SystemExit(f'Missing package: {name}; refusing to publish an incomplete repository')
    version, source = best
    dest = root / source.name
    if source.resolve() != dest.resolve():
        shutil.copy2(source, dest)
    print(f'{name}: {version}')
    selected.append(str(dest))
# repo-add replaces entries by package name. Include exactly one version of
# every supported package, including lib32, instead of adding all archives.
subprocess.run(['repo-add', '-n', str(root / 'nvgd.db.tar.gz'), *selected], check=True)
PY

if [[ "${1:-}" == --publish ]]; then
    git -C "$REPO_DIR" add -- .gitignore x86_64 README.md install.sh update-repo.sh packaging tests
    if ! git -C "$REPO_DIR" diff --cached --quiet; then
        git -C "$REPO_DIR" commit -m "Update nvgd repository packages $(date +'%Y-%m-%d')"
    fi
    git -C "$REPO_DIR" push origin main
    if ! gh release view packages --repo Geanziin/nvgd-repo >/dev/null 2>&1; then
        gh release create packages --repo Geanziin/nvgd-repo --title "nvgd packages" --notes "Arch/CachyOS binary repository."
    fi
    gh release upload packages "$REPO_DIR"/x86_64/*.pkg.tar.zst \
        "$REPO_DIR"/x86_64/nvgd.db.tar.gz "$REPO_DIR"/x86_64/nvgd.files.tar.gz \
        --repo Geanziin/nvgd-repo --clobber
fi

echo 'Repository generated. Publish with ./update-repo.sh --publish.'
echo 'Clients can update with sudo pacman -Syu; no partial upgrade is performed here.'
