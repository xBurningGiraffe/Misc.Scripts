#!/bin/bash

sudo yum -y install perch_siem tcpdump nmap unzip # Installs

#LT install
sudo curl https://labtech.radersolutions.com/lt.sh | sh

# networkcheck install
wget https://raw.githubusercontent.com/xBurningGiraffe/Misc.Scripts/main/networkjob.sh
chmod +x networkjob.sh
./networkjob.sh
rm -f siemconfig.sh


