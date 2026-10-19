#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/home/gean/Documents/nouveau-lab-repo"
LAB_DIR="/home/gean/Documents/nouveau-lab"

echo "==> Copiando novos pacotes de packaging/ para o repositório..."
cd "$REPO_DIR/x86_64"

# Copia pacotes mais recentes se existirem
if ls "$LAB_DIR"/packaging/mesa-git-lab/*.pkg.tar.zst 1>/dev/null 2>&1; then
    cp -u "$LAB_DIR"/packaging/mesa-git-lab/*.pkg.tar.zst .
fi

if ls "$LAB_DIR"/packaging/nouveau-lab-dkms/*.pkg.tar.zst 1>/dev/null 2>&1; then
    cp -u "$LAB_DIR"/packaging/nouveau-lab-dkms/*.pkg.tar.zst .
fi

if ls "$LAB_DIR"/packaging/gpu-screen-recorder-git/*.pkg.tar.zst 1>/dev/null 2>&1; then
    cp -u "$LAB_DIR"/packaging/gpu-screen-recorder-git/*.pkg.tar.zst .
fi

if ls "$LAB_DIR"/packaging/gpu-screen-recorder-ui-git/*.pkg.tar.zst 1>/dev/null 2>&1; then
    cp -u "$LAB_DIR"/packaging/gpu-screen-recorder-ui-git/*.pkg.tar.zst .
fi

echo "==> Atualizando base de dados do repositório (repo-add)..."
repo-add -n -R nouveau-lab.db.tar.gz *.pkg.tar.zst

echo "==> Enviando alterações para o GitHub..."
cd "$REPO_DIR"
git add .
if ! git diff --cached --quiet; then
    git commit -m "Update repository packages $(date +'%Y-%m-%d %H:%M')"
    git push origin main
    echo "==> Atualizando GitHub Release 'packages'..."
    gh release upload packages x86_64/* --clobber
    echo "==> Repositório atualizado e publicado no GitHub Pages com sucesso!"
else
    echo "==> Nenhuma alteração detectada nos pacotes."
fi

echo "==> Atualizando o cache local do pacman..."
sudo pacman -Sy

echo "==> Tudo pronto! Você pode rodar: sudo pacman -Syu"
