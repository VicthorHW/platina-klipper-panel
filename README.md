# Platina Klipper Panel 🚀

Solução técnica para implementação de interface de monitoramento dedicada para o Klipper, utilizando um dispositivo Android conectado via túnel de dados ADB (USB).

## 📍 Sumário
* [Visão Geral](#-visão-geral)
* [Diferenciais Técnicos](#-diferenciais-técnicos)
* [Requisitos de Hardware](#-requisitos-de-hardware)
* [Instalação no Host (Orange Pi/SBC)](#-instalação-no-host-orange-pisbc)
* [Configuração do Android](#-configuração-do-android)
* [Configuração do Moonraker (Update Manager)](#️-configuração-do-moonraker-update-manager)
* [Proteção de Tela (Anti-Burn-in)](#-proteção-de-tela-anti-burn-in)
* [Estrutura de Arquivos](#-estrutura-de-arquivos)
* [Licença](#-licença)

---

## 🔍 Visão Geral
O Platina Klipper Panel elimina a latência e a instabilidade inerentes às conexões Wi-Fi ao encapsular o tráfego VNC através do barramento USB. Utilizando a técnica de *ADB Forwarding*, o Host estabelece uma comunicação direta com o Android via `127.0.0.1`, permitindo que o dispositivo atue como uma tela de alta fidelidade para a impressora enquanto é alimentado pelo próprio Host.

## 🛠 Diferenciais Técnicos
* **Conectividade Low-Latency:** Tunelamento TCP via barramento USB.
* **Integração Nativa:** Automação via regras `udev` para detecção imediata de hardware.
* **Gestão de Ciclo de Vida:** Gerenciamento de brilho via software para preservação do painel.
* **Setup Automatizado:** Scripts para transferência rápida de *assets* e macros.

## 🔌 Requisitos de Hardware
* **Host:** Orange Pi Zero 3 (ou qualquer SBC compatível com Linux).
* **Display:** Dispositivo Android (com Depuração USB habilitada).
* **Conexão:** Cabo USB de alta qualidade (suporte a dados e carregamento).

## 💻 Instalação no Host (Orange Pi/SBC)
Siga os passos abaixo para configurar o ambiente no Linux:

```bash
# 1. Clonar o repositório
git clone [https://github.com/VicthorHW/platina-klipper-panel.git](https://github.com/VicthorHW/platina-klipper-panel.git) ~/scripts_vnc

# 2. Acessar o diretório e atribuir permissões
cd ~/scripts_vnc
chmod +x install.sh install_assets.sh

# 3. Executar o instalador do sistema
sudo ./install.sh
```

## 📱 Configuração do Android
Para facilitar a automação, o repositório inclui um script que envia a macro e o script de controle diretamente para o dispositivo.

1. Conecte o Android ao Host via USB.
2. Execute o script de *assets*:
```bash
./install_assets.sh
```
3. No Android, abra o **MacroDroid**.
4. Vá em **Importar/Exportar -> Importar** e selecione o arquivo `MacroDroid_Macros.mdr` que agora está na sua pasta *Download*.
5. O script `ligar_vnc.sh` também será copiado para a pasta *Download* e deve ser configurado como uma ação de "Shell Script" (com acesso Root) dentro da macro.

## ⚙️ Configuração do Moonraker (Update Manager)
Adicione o seguinte bloco ao seu arquivo `moonraker.conf` para receber atualizações automáticas:

```ini
[update_manager setup_android_vnc]
type: git_repo
path: ~/scripts_vnc
origin: https://github.com/VicthorHW/platina-klipper-panel.git
primary_branch: main
managed_services: klipper
```

## 💡 Proteção de Tela (Anti-Burn-in)
A lógica de proteção de painel implementada no script:

| Tempo | Ação | Nível de Brilho |
| :--- | :--- | :--- |
| **00:00** | Início do VNC (Localhost) | 200 (80%) |
| **10:00 min** | Ativação do *Dimming* | 12 (5%) |
| **20:00 min** | Display Sleep | Off (Deep Sleep) |

## 📂 Estrutura de Arquivos

| Arquivo | Função Técnica |
| :--- | :--- |
| `install.sh` | Instalador mestre e configuração de dependências de sistema. |
| `install_assets.sh` | Automação de transferência de arquivos (Macro/Scripts) para o Android. |
| `setup_adb_forward.sh` | Manutenção do túnel TCP via USB no Host. |
| `99-android-adb.rules` | Regra `udev` para automação via Vendor ID (Android 2717). |
| `ligar_vnc.sh` | Lógica de proteção e inicialização enviada ao Android. |
| `MacroDroid_Macros/` | Pasta contendo a macro `.mdr` pronta para importação. |

## 📄 Licença
Distribuído sob a licença MIT.