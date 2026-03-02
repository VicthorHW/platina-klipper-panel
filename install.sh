#!/bin/bash

# Platina Klipper Panel - Master Installer (Host + Android)
# This script configures the Linux system and deploys automation to the mobile device

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}== Starting Platina Klipper Panel Installation ==${NC}"

# 1. System Configuration (Requires Sudo)
echo -e "${YELLOW}[1/3] Configuring system rules and permissions on Host...${NC}"
# Copy UDEV rule that detects the Android device
sudo cp 99-android-adb.rules /etc/udev/rules.d/
# Copy the script that maintains the ADB tunnel active
sudo cp setup_adb_forward.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/setup_adb_forward.sh
# Reload rules for the system to recognize the device immediately
sudo udevadm control --reload-rules && sudo udevadm trigger

# 2. Android Verification (Required for the next step)
echo -e "${YELLOW}[2/3] Checking Android connection...${NC}"
echo "The device must be connected via USB with USB Debugging enabled now."

# Loop until device is detected
until adb get-state 1>/dev/null 2>&1; do
    echo -n "."
    sleep 2
done
echo -e "\n${GREEN}[+] Android detected!${NC}"

# 3. File Transfer to Android
echo -e "${YELLOW}[3/3] Sending macro and scripts to Android...${NC}"
DEST="/sdcard/Download"
MACRO="MacroDroid_Macros/MacroDroid_Macros.mdr"
VNC_SCRIPT="ligar_vnc.sh"

# Create destination folder if it doesn't exist
adb shell mkdir -p $DEST

if [ -f "$MACRO" ]; then
    adb push "$MACRO" "$DEST/"
    echo -e "${GREEN}[OK] Macro sent to Download folder.${NC}"
else
    echo -e "${YELLOW}[!] Warning: Macro file $MACRO not found.${NC}"
fi

if [ -f "$VNC_SCRIPT" ]; then
    adb push "$VNC_SCRIPT" "$DEST/"
    echo -e "${GREEN}[OK] VNC Script sent to Download folder.${NC}"
else
    echo -e "${YELLOW}[!] Warning: Script file $VNC_SCRIPT not found.${NC}"
fi

echo -e "${BLUE}==================================================${NC}"
echo -e "${GREEN}Installation complete!${NC}"
echo "Next step: Import the macro in MacroDroid from the Download folder."
echo -e "${BLUE}==================================================${NC}"