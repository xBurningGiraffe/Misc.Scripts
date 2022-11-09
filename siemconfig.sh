#!/bin/bash

sudo yum -y install wget perch_siem tcpdump nmap unzip # Installs

# networkcheck install
wget https://raw.githubusercontent.com/xBurningGiraffe/Misc.Scripts/main/networkjob.sh
chmod +x networkjob.sh
./networkjob.sh
rm -f siemconfig.sh

echo "Proceed with installing Labtech"

