#!/usr/bin/env bash
set -euo pipefail

echo "=============================================="
echo " Instalador nouveau-lab (Mesa Git + NVENC)    "
echo "=============================================="

if [ "$EUID" -ne 0 ]; then
  echo "Erro: Execute como root ou com sudo:"
  echo "  curl -sSL https://raw.githubusercontent.com/Geanziin/nouveau-lab-repo/main/install.sh | sudo bash"
  exit 1
fi

echo "==> Verificando repositório no /etc/pacman.conf..."
if grep -q "\[nouveau-lab\]" /etc/pacman.conf; then
    echo "Repositório [nouveau-lab] já existe no /etc/pacman.conf."
else
    echo "==> Adicionando [nouveau-lab] ao /etc/pacman.conf com prioridade..."
    cp /etc/pacman.conf /etc/pacman.conf.bak

    # Tenta inserir antes de [cachyos-v3] ou [cachyos] ou [core], ou no final
    python3 -c '
with open("/etc/pacman.conf", "r") as f:
    lines = f.readlines()

new_lines = []
inserted = False
for line in lines:
    clean = line.strip()
    if clean in ["[cachyos-v3]", "[cachyos]", "[core]"] and not inserted:
        new_lines.append("[nouveau-lab]\n")
        new_lines.append("SigLevel = Optional TrustAll\n")
        new_lines.append("Server = https://geanziin.github.io/nouveau-lab-repo/$arch\n\n")
        inserted = True
    new_lines.append(line)

if not inserted:
    new_lines.append("\n[nouveau-lab]\nSigLevel = Optional TrustAll\nServer = https://geanziin.github.io/nouveau-lab-repo/$arch\n")

with open("/etc/pacman.conf", "w") as f:
    f.writelines(new_lines)
'
fi

echo "==> Sincronizando banco de dados do pacman..."
pacman -Sy

echo "==> Instalando mesa-git customizado..."
pacman -S --needed nouveau-lab/mesa-git

echo ""
echo "=============================================="
echo " Instalação concluída com sucesso!            "
echo " Se este PC usar GPU NVIDIA com Nouveau,      "
echo " você também pode rodar:                      "
echo "   sudo pacman -S nouveau-lab-dkms            "
echo "=============================================="
