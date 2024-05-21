#!/bin/bash

# Define the device name
DEV_NAME="ligolo"

# Check if the TAP device already exists
if ip link show dev $DEV_NAME &> /dev/null; then
    echo "The TAP device $DEV_NAME already exists."
else
    # Create the TAP device
    sudo ip tuntap add mode tap user $(whoami) name $DEV_NAME

    # Check if the device was created successfully
    if [ $? -ne 0 ]; then
        echo "Failed to create TAP device $DEV_NAME."
        exit 1
    fi

    echo "TAP device $DEV_NAME created."
fi

# Bring up the device
sudo ip link set dev $DEV_NAME up
echo "TAP device $DEV_NAME is up."

# Prompt the user for the IP route
read -p "Enter the IP route to add (e.g., 10.0.0.0/24): " ip_route

# Validate input is not empty
if [ -z "$ip_route" ]; then
    echo "No IP route entered. Exiting without adding a route."
    exit 1
fi

# Add the IP route to the device
sudo ip route add $ip_route dev $DEV_NAME
if [ $? -eq 0 ]; then
    echo "Route $ip_route added to $DEV_NAME successfully."
else
    echo "Failed to add route $ip_route to $DEV_NAME."
    exit 1
fi
