#!/bin/bash

# Define the file path to the NetworkManager.conf file
nm_conf="/etc/NetworkManager/NetworkManager.conf"

# Add the dns=none line to the [main] section
sed -i '/^\[main\]$/a dns=none' $nm_conf

# Restart the NetworkManager service
systemctl restart NetworkManager.service

# Print a message to indicate the script has finished
# echo "Added 'dns=none' to the [main] section in $nm_conf and restarted the NetworkManager service."
