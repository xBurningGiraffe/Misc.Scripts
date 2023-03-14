#!/bin/bash

sudo yum -y install wget perch_siem tcpdump nmap unzip # Installs

# RADER Directory
dir_path="/opt/rader"

# Check for RADER Directory
if [ -d "$dir_path" ]; then
  echo "Directory already exists: $dir_path"
else
  sudo mkdir -p $dir_path
  
  sudo chmod 755 $dir_path
  
  sudo chown -R $USER:$USER $dir_path
fi

# networkcheck install
sudo wget -O $dir_path/networkcheck.sh https://raw.githubusercontent.com/xBurningGiraffe/Misc.Scripts/main/networkcheck.sh
sudo chmod +x $dir_path/networkcheck.sh

# Cronjob for networkcheck.sh
if crontab -l | grep -q "$dir_path/networkcheck.sh"; then
  echo "Cron job already exists"
else
  crontab -l > mycron
  echo "0 */2 * * * $dir_path/networkcheck.sh" >> mycron
  crontab mycron
  rm mycron

  echo "Proceed with installing Labtech"
fi
