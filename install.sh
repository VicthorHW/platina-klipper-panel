#!/bin/bash

# Platina Klipper Panel - Master Installer (Host + Android)
# Este script configura o sistema Linux (UDEV + Systemd) e envia a automação para o Android

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LOG_FILE="/tmp/klipper_vnc.log"

# Remove o log antigo se existir para evitar erros de permissão
if [ -f "$LOG_FILE" ]; then
    rm -f "$LOG_FILE"
fi

# Função para logar no terminal e no arquivo simultaneamente
log_msg() {
    local tipo="$1" # [INFO], [OK], [ERRO]
    local msg="$2"
    # Remove códigos de cores para o arquivo de log e limpa quebras de linha extras
    local clean_msg=$(echo -e "$msg" | sed 's/\x1B\[[0-9;]*[JKmsu]//g')
    echo -e "$msg"
    if [[ ! -z "$clean_msg" ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') $tipo $clean_msg" >> "$LOG_FILE"
    fi
}

# Inicia o arquivo de log limpo para a instalação
echo "==================================================" > "$LOG_FILE"
echo "LOG DE INSTALAÇÃO - PLATINA KLIPPER PANEL" >> "$LOG_FILE"
echo "Iniciado em: $(date)" >> "$LOG_FILE"
echo "==================================================" >> "$LOG_FILE"

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}      PLATINA KLIPPER PANEL - INSTALADOR          ${NC}"
echo -e "${BLUE}==================================================${NC}"

# 0. Verificação de Root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Erro: Este script precisa ser executado com sudo.${NC}"
   exit 1
fi

REAL_USER=${SUDO_USER:-pi}

# 1. Verificação de Dependências
log_msg "[INFO]" "${YELLOW}[1/6] Verificando dependências do sistema...${NC}"

check_and_install() {
    if ! command -v $1 &> /dev/null; then
        log_msg "[INFO]" "Dependência '$1' não encontrada."
        read -p "Deseja instalar $1 agora? (s/n): " INSTALL_DEP
        if [[ "$INSTALL_DEP" == "s" || "$INSTALL_DEP" == "S" ]]; then
            apt-get update && apt-get install -y $2
            log_msg "[OK]" "Instalado: $1"
        else
            log_msg "[ERRO]" "${RED}Erro: $1 é necessário para continuar.${NC}"
            exit 1
        fi
    else
        log_msg "[OK]" "Dependência encontrada: $1"
    fi
}

check_and_install "adb" "android-tools-adb"
check_and_install "lsusb" "usbutils"
check_and_install "comm" "coreutils"

# 2. Identificação do Dispositivo (Vendor ID)
echo -e "\n"
log_msg "[INFO]" "${YELLOW}[2/6] Identificação do Dispositivo USB${NC}"
VENDOR_ID=""

read -p "Você já sabe o Vendor ID do seu celular? (s/n): " JASAIBE

if [[ "$JASAIBE" == "s" || "$JASAIBE" == "S" ]]; then
    read -p "Digite o ID de 4 dígitos (ex: 18d1 ou 2717): " VENDOR_ID
else
    log_msg "[INFO]" "${BLUE}--- Assistente de Detecção Automática ---${NC}"
    echo -e "${RED}PASSO 1:${NC} Certifique-se que o celular ${RED}ESTÁ DESCONECTADO${NC} agora."
    read -p "Pressione [Enter] quando desconectado..."

    USB_BEFORE=$(lsusb | awk '{print $6}' | cut -d: -f1 | sort)

    echo -e "${GREEN}PASSO 2:${NC} Agora, ${GREEN}CONECTE O CELULAR${NC} ao USB."
    read -p "Pressione [Enter] após conectar e aguardar 3 segundos..."

    USB_AFTER=$(lsusb | awk '{print $6}' | cut -d: -f1 | sort)
    VENDOR_ID=$(comm -13 <(echo "$USB_BEFORE") <(echo "$USB_AFTER") | head -n 1)

    if [ -z "$VENDOR_ID" ]; then
        log_msg "[ERRO]" "${RED}[!] Erro: Não detectamos nenhum dispositivo novo.${NC}"
        read -p "Deseja digitar o ID manualmente agora? (ex: 18d1): " VENDOR_ID
    else
        log_msg "[OK]" "${GREEN}[+] Sucesso! ID detectado: $VENDOR_ID${NC}"
    fi
fi

if [ -z "$VENDOR_ID" ]; then exit 1; fi

# 3. Criação do Script de Túnel
echo -e "\n"
log_msg "[INFO]" "${YELLOW}[3/6] Criando scripts de automação...${NC}"

cat <<EOF > /usr/local/bin/setup_adb_forward.sh
#!/bin/bash
LOG_FILE="/tmp/klipper_vnc.log"
ADB_BIN="/usr/bin/adb"
export HOME="/home/$REAL_USER"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

echo "------------------------------------------" >> \$LOG_FILE
echo "\$(date '+%Y-%m-%d %H:%M:%S') [USB] Dispositivo CONECTADO" >> \$LOG_FILE

\$ADB_BIN start-server >> \$LOG_FILE 2>&1

for i in {1..20}; do
    if \$ADB_BIN devices | grep -qw "device"; then
        echo "\$(date '+%Y-%m-%d %H:%M:%S') [ADB] Pronto após \$i segundos." >> \$LOG_FILE
        break
    fi
    sleep 1
done

echo "\$(date '+%Y-%m-%d %H:%M:%S') [TÚNEL] Configurando porta 5900..." >> \$LOG_FILE
\$ADB_BIN reverse --remove-all >> \$LOG_FILE 2>&1
\$ADB_BIN reverse tcp:5900 tcp:5900 >> \$LOG_FILE 2>&1

if [ \$? -eq 0 ]; then
    echo "\$(date '+%Y-%m-%d %H:%M:%S') [SUCESSO] Túnel estabelecido!" >> \$LOG_FILE
else
    echo "\$(date '+%Y-%m-%d %H:%M:%S') [ERRO] Falha ao configurar túnel." >> \$LOG_FILE
fi
echo "------------------------------------------" >> \$LOG_FILE
EOF

chmod +x /usr/local/bin/setup_adb_forward.sh

# 4. Configuração do Serviço e UDEV
echo -e "\n"
log_msg "[INFO]" "${YELLOW}[4/6] Configurando serviços de sistema...${NC}"

cat <<EOF > /etc/systemd/system/klipper-adb.service
[Unit]
Description=Klipper ADB VNC Tunnel Service
After=network.target

[Service]
Type=oneshot
User=$REAL_USER
ExecStart=/usr/local/bin/setup_adb_forward.sh
ExecStop=/bin/bash -c 'echo "------------------------------------------" >> $LOG_FILE; echo "\$(date "+%%Y-%%m-%%d %%H:%%M:%%S") [USB] Dispositivo DESCONECTADO" >> $LOG_FILE; echo "------------------------------------------" >> $LOG_FILE'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"$VENDOR_ID\", ACTION==\"add\", RUN+=\"/usr/bin/systemctl restart klipper-adb.service\"" > /etc/udev/rules.d/99-android-adb.rules
echo "SUBSYSTEM==\"usb\", ENV{ID_VENDOR_ID}==\"$VENDOR_ID\", ACTION==\"remove\", RUN+=\"/usr/bin/systemctl stop klipper-adb.service\"" >> /etc/udev/rules.d/99-android-adb.rules

systemctl daemon-reload
udevadm control --reload-rules && udevadm trigger
log_msg "[OK]" "Serviços de automação configurados."

# 5. Verificação ADB e Transferência
echo -e "\n"
log_msg "[INFO]" "${YELLOW}[5/6] Verificando comunicação ADB e enviando arquivos...${NC}"
until sudo -u $REAL_USER adb get-state 1>/dev/null 2>&1; do
    echo -n "."
    sleep 2
done

DEST="/sdcard/Download"
sudo -u $REAL_USER adb shell mkdir -p $DEST

if [ -f "MacroDroid_Macros/MacroDroid_Macros.mdr" ]; then
    sudo -u $REAL_USER adb push "MacroDroid_Macros/MacroDroid_Macros.mdr" "$DEST/"
    log_msg "[OK]" "Macro enviada para o Android."
fi

if [ -f "ligar_vnc.sh" ]; then
    sudo -u $REAL_USER adb push "ligar_vnc.sh" "$DEST/"
    log_msg "[OK]" "Script VNC enviado para o Android."
fi

# 6. Finalização e Início Imediato
echo -e "\n"
log_msg "[INFO]" "${YELLOW}[6/6] Finalizando e iniciando túnel...${NC}"

# Tenta iniciar o serviço agora mesmo para não precisar replugar
systemctl restart klipper-adb.service

echo -e "\n${BLUE}==================================================${NC}"
log_msg "[OK]" "${GREEN}INSTALAÇÃO CONCLUÍDA COM SUCESSO!${NC}"
echo "O túnel foi iniciado automaticamente agora."
echo "Para monitorar eventos de USB: tail -f $LOG_FILE"
echo -e "${BLUE}==================================================${NC}"