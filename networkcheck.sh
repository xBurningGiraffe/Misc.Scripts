#!/bin/bash

# OpenDNS IPs
TARGET_IP1=208.67.220.220
TARGET_IP2=208.67.222.222

# Google IPs
TARGET_IP3=8.8.8.8
TARGET_IP4=8.8.4.4

# Initialize a counter for successful pings
count=0

# Get the IP address for interface ens1
IP_ADDR=$(ip addr show ens1 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

# Get the IP address for the gateway of interface ens1
GATEWAY_IP=$(ip route show dev ens1 | awk '/default/ {print $3}')

# Ping the gateway IP address
ping -c 5 $GATEWAY_IP > /dev/null 2>&1
if [ $? -eq 0 ]; then
  echo "Ping to gateway $GATEWAY_IP was successful."
else
  echo "Ping to gateway $GATEWAY_IP failed. Trying target IPs..."

  # Try to ping each target IP address
  ping -c 5 $TARGET_IP1 > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Ping to $TARGET_IP1 was successful."
    ((count++))
  fi

  ping -c 5 $TARGET_IP2 > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Ping to $TARGET_IP2 was successful."
    ((count++))
  fi

  ping -c 5 $TARGET_IP3 > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Ping to $TARGET_IP3 was successful."
    ((count++))
  fi

  ping -c 5 $TARGET_IP4 > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "Ping to $TARGET_IP4 was successful."
    ((count++))
  fi

  # If at least 3 of the target IP addresses respond, stop the script
  if [ $count -ge 3 ]; then
    exit 0
  else
   /sbin/reboot
  fi
fi
