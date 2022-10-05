#!/bin/bash

# OpenDNS
TARGET_IP1=208.67.220.220
TARGET_IP2=208.67.222.222

# Ping IPs
count1=$(ping -c 5 $TARGET_IP1 | grep from* | wc -l)
count2=$(ping -c 5 $TARGET_IP2 | grep from* | wc -l)

if [ $count1 -eq 0 ] ; then
    /sbin/reboot
elif
    [ $count2 -eq 0 ] ; then
    /sbin/reboot
else
# Network is up
    :
fi
