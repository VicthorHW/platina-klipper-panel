#!/bin/bash
# Arquivo: install.sh

# Script para automatizar a cópia de arquivos para o Android (Host)
# Requer ADB instalado e Depuração USB ativa

# Cores para o terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

echo -e "${BLUE}== Configuração de Assets Android ==${NC}"

# 1. Verificar se o dispositivo está conectado
if ! adb get-state 1>/dev/null 2>&1; then
    echo "Erro: Nenhum dispositivo Android detectado via ADB."
    echo "Verifique o cabo e se a Depuração USB está ativa."
    exit 1
fi

echo -e "${GREEN}[+] Dispositivo detectado.${NC}"

# 2. Definir caminhos
DEST_PATH="/sdcard/Download"
MACRO_FILE="MacroDroid_Macros/MacroDroid_Macros.mdr"
VNC_SCRIPT="ligar_vnc.sh"

# 3. Criar pasta de destino se não existir (opcional, Download sempre existe)
adb shell mkdir -p $DEST_PATH

# 4. Copiar a Macro do MacroDroid
if [ -f "$MACRO_FILE" ]; then
    echo "Copiando macro para o celular..."
    adb push "$MACRO_FILE" "$DEST_PATH/"
else
    echo "Aviso: Arquivo $MACRO_FILE não encontrado no repositório."
fi

# 5. Copiar o script de inicialização do VNC
if [ -f "$VNC_SCRIPT" ]; then
    echo "Copiando script VNC para o celular..."
    adb push "$VNC_SCRIPT" "$DEST_PATH/"
    # Ajusta permissão de execução no Android (se o sistema permitir no /sdcard)
    adb shell chmod +x "$DEST_PATH/$VNC_SCRIPT"
else
    echo "Aviso: Arquivo $VNC_SCRIPT não encontrado no repositório."
fi

echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}Sucesso!${NC}"
echo "Os arquivos foram enviados para a pasta 'Download' do seu Android."
echo "Instruções:"
echo "1. Abra o MacroDroid no celular."
echo "2. Vá em 'Importar/Exportar' -> 'Importar'."
echo "3. Selecione o arquivo 'MacroDroid_Macros.mdr' na pasta Download."
echo -e "${BLUE}=====================================${NC}"