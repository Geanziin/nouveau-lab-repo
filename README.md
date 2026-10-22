# nvgd Arch Linux / CachyOS repository

Pacotes do [nvgd](https://github.com/Geanziin/nvgd) e do
[nvgd-dkms](https://github.com/Geanziin/nvgd-dkms).
OpenGL usa nvc0/NAK; Vulkan usa **NVK/NAK nativo**, sem Zink ou ANGLE.
Os ICDs Vulkan mantêm o nome upstream `nouveau_icd`.

## Configuração

Coloque este bloco **antes dos outros repositórios** em `/etc/pacman.conf`:

```ini
[nvgd]
SigLevel = Optional TrustAll
Server = https://geanziin.github.io/nvgd-repo/$arch
```

Remova blocos antigos `[nouveau-lab]` e `[nvgd-dkms]`. Para migrar automaticamente:

```bash
curl -fLO https://raw.githubusercontent.com/Geanziin/nvgd-repo/main/install.sh
# Revise o script antes de executá-lo.
sudo bash install.sh
```

Os pacotes não são assinados; `Optional TrustAll` reduz a verificação de confiança.
Use somente se confiar neste repositório. Para atualizar, use `sudo pacman -Syu`,
não uma atualização parcial com `pacman -Sy` seguida de instalação isolada.

## Pacotes

| Pacote | Conteúdo |
| --- | --- |
| `nvgd-dkms` | Módulo de kernel nvgd com GSP e telemetria |
| `mesa-git` | Mesa 64-bit, OpenGL nativo, NVK, VA-API e vídeo |
| `lib32-mesa-git` | Mesa 32-bit, OpenGL nativo e NVK para Steam/Proton |
| `gpu-screen-recorder-git` | Captura e gravação |
| `gpu-screen-recorder-ui-git` | Interface gráfica |
| `gpu-screen-recorder-notification-git` | Notificações de gravação e replay |

Mesa 32/64-bit: `1:27.0.0_devel.r231957.g72a232a17dbf-1`.
DKMS: `1.0.0-18`. O build 32-bit agora otimiza C/C++ e Rust em nível 3,
incluindo NVK, NIR e NAK. Isso corrige overhead de CPU do build anterior;
não representa garantia de FPS para um jogo específico.
NVENC: upload de NV12 em blocos de 16 bytes no caminho de cópia, preservando
o zero-copy padrão. Decoder H.264: menos limpeza de memória e realocações
do bitstream. As fences e a sincronização de vídeo foram mantidas.

```bash
sudo pacman -Syu nvgd/mesa-git nvgd/lib32-mesa-git nvgd/nvgd-dkms
```

Reinicie após atualizar o módulo de kernel; para atualizar apenas Mesa,
reabra os aplicativos para carregar as bibliotecas novas.

## Atualização pelo mantenedor

`./update-repo.sh` seleciona por metadados/vercmp a versão mais recente dos seis
pacotes em `$LAB_DIR/packaging` ou `x86_64` e gera `nvgd.db.tar.gz`.
`./update-repo.sh --publish` também faz commit/push e atualiza o release
[`packages`](https://github.com/Geanziin/nvgd-repo/releases/tag/packages).
As receitas locais estão em `packaging/`; ainda dependem da árvore de build do lab.

Teste de referência dos hotpaths (144 combinações NV12 e limites do bitstream):

```bash
python3 tests/video-hotpaths.py /caminho/para/mesa
NVGD_TEST_SANITIZE=1 python3 tests/video-hotpaths.py /caminho/para/mesa
```
