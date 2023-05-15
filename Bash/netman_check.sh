#!/bin/bash

# Check if the "dns=none" line exists in NetworkManager.conf
if grep -q "dns=none" /etc/NetworkManager/NetworkManager.conf; then
    echo "The 'dns=none' line already exists in NetworkManager.conf."
else
    # Backup the original configuration file
    sudo cp /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/NetworkManager.conf.bak
    
    # Use sed to add the "dns=none" line at the end of the file
    sudo sed -i '$ a dns=none' /etc/NetworkManager/NetworkManager.conf
    
    echo "The 'dns=none' line has been added to NetworkManager.conf."
fi

# Restart the NetworkManager service
sudo systemctl restart NetworkManager.service

echo "NetworkManager service has been restarted."
