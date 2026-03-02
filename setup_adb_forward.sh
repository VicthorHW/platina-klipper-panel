#!/bin/bash
# Ficheiro: setup_adb_forward.sh
# Este script agora é otimizado para rodar via systemd service

LOG_FILE="/tmp/klipper_vnc.log"

echo "------------------------------------------" >> $LOG_FILE
echo "Serviço de Túnel iniciado em: $(date)" >> $LOG_FILE

ADB_BIN="/usr/bin/adb"
# Definimos o HOME para que o ADB encontre as chaves de autorização do utilizador pi
export HOME="/home/pi"
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Hardware stabilization
sleep 2

echo "Limpando túneis anteriores..." >> $LOG_FILE
$ADB_BIN kill-server >> $LOG_FILE 2>&1
$ADB_BIN start-server >> $LOG_FILE 2>&1

echo "Aguardando detecção do dispositivo Android..." >> $LOG_FILE
# Loop de 30 segundos para garantir a detecção durante o boot
for i in {1..30}; do
    if $ADB_BIN devices | grep -qw "device"; then
        echo "Dispositivo detectado com sucesso após $i segundos!" >> $LOG_FILE
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "TIMEOUT: Celular não ficou pronto para ADB." >> $LOG_FILE
        exit 1
    fi
    sleep 1
done

echo "Configurando túnel reverso (5900 -> 5900)..." >> $LOG_FILE
$ADB_BIN reverse --remove-all >> $LOG_FILE 2>&1
$ADB_BIN reverse tcp:5900 tcp:5900 >> $LOG_FILE 2>&1

if [ $? -eq 0 ]; then
    echo "SUCESSO: Túnel estabelecido. bVNC pronto para conectar em 127.0.0.1" >> $LOG_FILE
    $ADB_BIN reverse --list >> $LOG_FILE
else
    echo "ERRO: Falha crítica ao configurar reverse tunnel." >> $LOG_FILE
fi

echo "Serviço finalizado em: $(date)" >> $LOG_FILE
echo "------------------------------------------" >> $LOG_FILE