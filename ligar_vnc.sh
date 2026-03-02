#!/system/bin/sh
# File: ligar_vnc.sh

# Automation and screen protection script for display
# Should be executed via MacroDroid or Terminal (Root)

# 1. WAKE UP: Increase brightness and start Localhost connection (ADB Tunnel)
settings put system screen_brightness 200
am start -a android.intent.action.VIEW -d "vnc://127.0.0.1:5900?ViewOnly=no&AutoConnect=yes"

# 2. MONITORING: Keep screen active for 10 minutes
sleep 600

# 3. DIMMING: Reduce brightness to minimum to protect against burn-in
settings put system screen_brightness 12

# 4. FINALIZATION: Wait another 10 minutes and turn off screen
sleep 600
input keyevent 26