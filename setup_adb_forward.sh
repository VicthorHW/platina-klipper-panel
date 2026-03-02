#!/bin/bash
# File: setup_adb_forward.sh

# Logs the execution attempt
echo "UDEV triggered ADB script at $(date)" >> /tmp/klipper_vnc.log

# Use absolute path for adb to avoid path issues with UDEV
ADB_BIN="/usr/bin/adb"

# Start ADB server
$ADB_BIN start-server

# Wait for hardware stabilization
sleep 2

# CRITICAL: We use 'reverse' because bVNC is on the phone 
# looking for a server at its own 127.0.0.1:5900
$ADB_BIN reverse --remove-all
$ADB_BIN reverse tcp:5900 tcp:5900

if [ $? -eq 0 ]; then
    echo "SUCCESS: ADB Reverse Tunnel TCP:5900 established" >> /tmp/klipper_vnc.log
else
    echo "ERROR: Failed to establish ADB tunnel" >> /tmp/klipper_vnc.log
fi