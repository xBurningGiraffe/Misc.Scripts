#!/bin/bash

sudo yum install wget perch_siem tcpdump nmap unzip -y # Installs

# RADER Directory
dir_path="/opt/rader"

# Check for RADER Directory
if [ -d "$dir_path" ]; then
  echo "Directory already exists: $dir_path"
else
# Create RADER directory
  sudo mkdir -p $dir_path
  sudo chmod 755 $dir_path
  sudo chown -R $USER:$USER $dir_path
fi

# Check if the "dns=none" line exists in NetworkManager.conf
if grep -q "dns=none" /etc/NetworkManager/NetworkManager.conf; then
    echo "The 'dns=none' line already exists in NetworkManager.conf."
else
    # Backup the original configuration file
    sudo cp /etc/NetworkManager/NetworkManager.conf /etc/NetworkManager/NetworkManager.conf.bak
    
    # Use sed to add the "dns=none" line at the end of the file
    sudo sed -i '/^\[main\]$/a dns=none' /etc/NetworkManager/NetworkManager.conf
    
    echo "The 'dns=none' line has been added to NetworkManager.conf."
fi

# Restart the NetworkManager service
sudo systemctl restart NetworkManager.service

echo "NetworkManager service has been restarted."

# Pull netman_check.sh script and create daily cronjob
NETMAN_CHECK="/opt/rader/netman_check.sh"
NETMAN_CRONJOB="/opt/rader/netman_cronjob"
NETMAN_URL="https://raw.githubusercontent.com/xBurningGiraffe/Misc.Scripts/main/Bash/netman_check.sh"

# Get script
sudo wget -O "$NETMAN_CHECK" "$NETMAN_URL"

# Change perms and create cronjob file
sudo chmod +x "$NETMAN_CHECK"
sudo echo "0 0 * * * /bin/bash $NETMAN_CHECK" >> sudo tee "$NETMAN_CRONJOB" > /dev/null

# Create cronjob
sudo crontab "$NETMAN_CRONJOB"

echo "Proceed with installing Labtech"
fi
