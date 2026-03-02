#!/bin/bash

# Platina Klipper Panel - Master Installer (Host + Android)
# Este script configura o sistema Linux (UDEV + Systemd) e envia a automação para o Android

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}      PLATINA KLIPPER PANEL - INSTALADOR          ${NC}"
echo -e "${BLUE}==================================================${NC}"

# 0. Verificação de Root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Erro: Este script precisa ser executado com sudo.${NC}"
   echo "Use: sudo ./install.sh"
   exit 1
fi

REAL_USER=${SUDO_USER:-pi}

# 1. Assistente de Identificação do Android (Vendor ID)
echo -e "${YELLOW}[1/5] Identificação do Dispositivo USB${NC}"
echo "Para que o painel ligue sozinho ao plugar o cabo, o sistema precisa"
echo "reconhecer o 'RG' (Vendor ID) do seu celular."
echo ""

VENDOR_ID=""

read -p "Você já sabe o Vendor ID do seu celular? (s/n): " JASAIBE

if [[ "$JASAIBE" == "s" || "$JASAIBE" == "S" ]]; then
    read -p "Digite o ID de 4 dígitos (ex: 18d1 ou 2717): " VENDOR_ID
else
    echo -e "${BLUE}--- Assistente de Detecção Automática ---${NC}"
    echo "Explicando o processo:"
    echo "Primeiro, vamos listar o que já está conectado (sem o celular)."
    echo "Depois, você conecta o celular e veremos qual novo item apareceu."
    echo ""
    echo -e "${RED}PASSO 1:${NC} Certifique-se que o celular ${RED}ESTÁ DESCONECTADO${NC} do USB agora."
    read -p "Pressione [Enter] quando o celular estiver desconectado..."
    
    # Primeiro "print" do sistema USB
    USB_BEFORE=$(lsusb | awk '{print $6}' | cut -d: -f1 | sort)
    echo -e "${BLUE}[i] Lista de dispositivos atuais mapeada.${NC}"
    echo ""

    echo -e "${GREEN}PASSO 2:${NC} Agora, ${GREEN}CONECTE O CELULAR${NC} ao USB."
    echo "(Certifique-se que a 'Depuração USB' está ativa nas opções de desenvolvedor)."
    read -p "Pressione [Enter] após conectar e aguardar 3 segundos..."
    
    # Segundo "print" do sistema USB
    USB_AFTER=$(lsusb | awk '{print $6}' | cut -d: -f1 | sort)

    # Compara as duas listas para achar o ID novo
    VENDOR_ID=$(comm -13 <(echo "$USB_BEFORE") <(echo "$USB_AFTER") | head -n 1)

    if [ -z "$VENDOR_ID" ]; then
        echo -e "${RED}[!] Erro: Não detectamos nenhum dispositivo novo.${NC}"
        echo "Isso pode acontecer se o cabo for apenas de carga ou a depuração estiver desligada."
        echo ""
        echo "Como achar manualmente:"
        echo "1. Digite 'lsusb' no terminal."
        echo "2. Procure uma linha como: ID ${GREEN}18d1${NC}:4ee7 Google Inc."
        echo "3. O ID são os 4 dígitos antes dos dois pontos."
        echo ""
        read -p "Deseja digitar o ID manualmente agora? (ex: 18d1): " VENDOR_ID
    else
        echo -e "${GREEN}[+] Sucesso! O novo dispositivo detectado tem o ID: $VENDOR_ID${NC}"
    fi
fi

if [ -z "$VENDOR_ID" ]; then
    echo -e "${RED}Erro: Vendor ID não definido. A instalação não pode configurar a automação.${NC}"
    exit 1
fi

# 2. Configuração do Sistema (Host)
echo -e "\n${YELLOW}[2/5] Configurando serviços e regras no Host...${NC}"

# Copiar o script de túnel
if [ -f "setup_adb_forward.sh" ]; then
    cp setup_adb_forward.sh /usr/local/bin/
    chmod +x /usr/local/bin/setup_adb_forward.sh
    echo -e "${GREEN}[OK] Script de túnel copiado para /usr/local/bin/.${NC}"
else
    echo -e "${RED}[!] Erro: setup_adb_forward.sh não encontrado no diretório atual.${NC}"
    exit 1
fi

# Criar o arquivo de serviço Systemd
echo "Criando serviço de sistema para o usuário $REAL_USER..."
cat <<EOF > /etc/systemd/system/klipper-adb.service
[Unit]
Description=Klipper ADB VNC Tunnel Service
After=network.target

[Service]
Type=oneshot
User=$REAL_USER
ExecStart=/usr/local/bin/setup_adb_forward.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Configurar a Regra UDEV com o ID coletado
echo "Configurando regra de detecção USB (ID $VENDOR_ID)..."
echo "SUBSYSTEM==\"usb\", ATTR{idVendor}==\"$VENDOR_ID\", ACTION==\"add\", RUN+=\"/usr/bin/systemctl start klipper-adb.service\"" > /etc/udev/rules.d/99-android-adb.rules

systemctl daemon-reload
udevadm control --reload-rules && udevadm trigger
echo -e "${GREEN}[OK] Automação configurada para o ID $VENDOR_ID.${NC}"

# 3. Verificação do Android (ADB)
echo -e "\n${YELLOW}[3/5] Verificando comunicação ADB...${NC}"
echo "Olhe para a tela do celular. Se aparecer 'Permitir depuração USB?', marque 'Sempre' e aceite."

until sudo -u $REAL_USER adb get-state 1>/dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e "\n${GREEN}[+] Comunicação estabelecida com o Android!${NC}"

# 4. Transferência de Arquivos
echo -e "\n${YELLOW}[4/5] Enviando arquivos de automação para o celular...${NC}"
DEST="/sdcard/Download"
MACRO="MacroDroid_Macros/MacroDroid_Macros.mdr"
VNC_SCRIPT="ligar_vnc.sh"

sudo -u $REAL_USER adb shell mkdir -p $DEST

if [ -f "$MACRO" ]; then
    sudo -u $REAL_USER adb push "$MACRO" "$DEST/"
    echo -e "${GREEN}[OK] Macro enviada para a pasta Download.${NC}"
fi

if [ -f "$VNC_SCRIPT" ]; then
    sudo -u $REAL_USER adb push "$VNC_SCRIPT" "$DEST/"
    echo -e "${GREEN}[OK] Script auxiliar enviado.${NC}"
fi

# 5. Finalização
echo -e "\n${BLUE}==================================================${NC}"
echo -e "${GREEN}INSTALAÇÃO CONCLUÍDA!${NC}"
echo -e "ID do Celular: ${YELLOW}$VENDOR_ID${NC}"
echo ""
echo "Instruções finais:"
echo "1. No celular, abra o MacroDroid e importe o arquivo na pasta Download."
echo "2. Agora você pode desconectar e conectar o USB para testar."
echo "3. O log de conexão fica em: /tmp/klipper_vnc.log"
echo -e "${BLUE}==================================================${NC}"