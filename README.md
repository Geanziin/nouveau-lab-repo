# nouveau-lab Arch Linux / CachyOS Repository

Repositório customizado com pacotes binários prontos para uso do **Mesa** (com suporte a NVENC H.264 / decodificação Vulkan Video) e do módulo de kernel **Nouveau DKMS** (com suporte nativo ao GSP-RM 615.78.08 e telemetria para RTX 3050 GA107).

## 🚀 Como adicionar ao seu sistema

Abra o arquivo `/etc/pacman.conf` com seu editor preferido (como `sudo nano /etc/pacman.conf` ou `sudo micro /etc/pacman.conf`) e adicione as seguintes linhas no final do arquivo:

```ini
[nouveau-lab]
SigLevel = Optional TrustAll
Server = https://geanziin.github.io/nouveau-lab-repo/$arch
Server = https://github.com/Geanziin/nouveau-lab-repo/releases/download/packages
```

Em seguida, atualize o banco de dados de repositórios do pacman:

```bash
sudo pacman -Sy
```

---

## 📦 Pacotes disponíveis

- **`mesa-git`**: Mesa 26.3-devel compilado com suporte a NVENC H.264, decodificação Vulkan Video, correções Zink YUV e aceleração gráfica.
- **`nouveau-lab-dkms`**: Módulo de kernel Nouveau como DKMS (recompila sozinho a cada atualização de kernel do CachyOS/Arch), incluindo firmware host loader 615.
- **`gpu-screen-recorder-git`**: GPU Screen Recorder adaptado para suporte nativo ao nosso driver Nouveau VA-API NVENC (GeForce RTX 3050).
- **`gpu-screen-recorder-ui-git`**: Interface gráfica (GUI) e atalho/ícone de desktop para o GPU Screen Recorder.

---

## ⚡ Como instalar

Para instalar os pacotes diretamente via pacman:

```bash
sudo pacman -S mesa-git nouveau-lab-dkms gpu-screen-recorder-git gpu-screen-recorder-ui-git
```

Para atualizar no dia a dia junto com os demais pacotes do sistema:

```bash
sudo pacman -Syu
```
