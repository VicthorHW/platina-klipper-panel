#!/bin/bash
# File: setup_adb_forward.sh

# Manages port forwarding for VNC via ADB
# This script is called automatically by the UDEV rule

# Start ADB server if not running
adb start-server

# Wait for hardware stabilization
sleep 2

# Clear old forwards and define the new tunnel
# Maps port 5900 (VNC) from Android to Orange Pi's Localhost
adb forward --remove-all
adb forward tcp:5900 tcp:5900

echo "ADB Forwarding Tunnel TCP:5900 established at $(date)" >> /tmp/klipper_vnc.log