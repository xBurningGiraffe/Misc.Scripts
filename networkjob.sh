#!/bin/bash

mkdir /opt/rader
wget https://raw.githubusercontent.com/xBurningGiraffe/Misc.Scripts/main/networkcheck.sh -P /opt/rader/networkcheck.sh
chmod +x /opt/rader/networkcheck.sh
crontab -l > mycron
echo "0 */2 * * * /opt/rader/networkdown.sh" >> mycron
crontab mycron
rm -f mycron
rm -f networkjob.sh
