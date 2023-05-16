#!/bin/bash

if ! pgrep -x "ltechagent" > /dev/null
then
    echo "ltechagent is not running. Restarting..."
    sudo systemctl restart ltechagent
    sudo systemctl daemon-reload
else
    echo "ltechagent is already running."
fi
