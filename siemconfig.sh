#!/bin/bash

sudo yum -y install perch_siem tcpdump nmap wget unzip # Installs

#LT install
mkdir -p /tmp/lt_install
cd /tmp/lt_install
wget -O lt.zip http://labtech.radersolutions.com/labtech/transfer/installers/LTechAgent_x86_64_loc_412.zip
unzip lt.zip
cd LTechAgent
chmod a+x install.sh
./install.sh
rm -rf /tmp/lt11_install

# networkcheck install
wget https://raw.githubusercontent.com/xBurningGiraffe/Misc.Scripts/main/networkjob.sh
chmod +x networkjob.sh
./networkjob.sh


