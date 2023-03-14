#!/bin/bash

# OpenDNS
TARGET_IP1=208.67.220.220
TARGET_IP2=208.67.222.222
# Google DNS
TARGET_IP3=8.8.8.8
TARGET_IP4=8.8.4.4

# Check network connectivity
ping -c 5 $TARGET_IP1 > /dev/null 2>&1
if [ $? -eq 0 ]; then
  exit 0
fi

ping -c 5 $TARGET_IP2 > /dev/null 2>&1
if [ $? -eq 0 ]; then
  exit 0
fi

ping -c 5 $TARGET_IP3 > /dev/null 2>&1
if [ $? -eq 0 ]; then
  exit 0
fi

ping -c 5 $TARGET_IP4 > /dev/null 2>&1
if [ $? -eq 0 ]; then
  exit 0
fi

# Reboots if no IPs are responding
/sbin/reboot
