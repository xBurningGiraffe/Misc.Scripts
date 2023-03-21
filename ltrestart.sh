#!/bin/bash

if ! pgrep -x "ltechagent" > /dev/null
then
    echo "ltechagent is not running. Restarting..."
    systemctl restart ltechagent
    systemctl daemon-reload
else
    echo "ltechagent is already running."
fi
