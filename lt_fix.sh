#!/bin/bash

sudo systemctl stop ltechagent
sudo systemctl disable ltechagent
cd /usr/local/ltechagent
sudo sh uninstaller.sh
wget -O lt.zip http://labtech.radersolutions.com/labtech/transfer/installers/LTechAgent_x86_64_loc_412.zip
unzip lt.zip
cd LTechAgent && chmod a+x install.sh
sudo sh install.sh
sudo systemctl daemon-reload
sudo systemctl start ltechagent
sudo systemctl status ltechagent
#!/bin/bash

if ! pgrep -x "ltechagent" > /dev/null
then
    echo "ltechagent is not running. Restarting..."
    systemctl restart ltechagent
    systemctl daemon-reload
else
    echo "ltechagent is already running."
fi

wget https://raw.githubusercontent.com/xBurningGiraffe/Misc.Scripts/main/siemconfig.sh | chmod +x siemconfig.sh
sudo sh siemconfig.sh

