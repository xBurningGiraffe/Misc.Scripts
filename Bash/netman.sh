#!/bin/bash

# Add the dns=none line to the [main] section in NetworkManager.conf
sudo sed -i '/^\[main\]$/a dns=none' /etc/NetworkManager/NetworkManager.conf

# Restart the NetworkManager service
sudo systemctl restart NetworkManager.service

# Print a message to indicate the script has finished
echo "Added 'dns=none' to the [main] section in NetworkManager.conf and restarted the NetworkManager service."
