#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Download the configuration file and place it in /etc/sysctl.d/
wget -O /etc/sysctl.d/99-custom.conf https://raw.githubusercontent.com/Al-Bsharat/proxy-server-setup/refs/heads/main/99-custom.conf

# Reload system-wide sysctl settings
sudo sysctl --system

# Set ulimit to the maximum possible value and make it persistent
# Get the maximum allowed number of open file descriptors
MAX_ULIMIT=$(ulimit -Hn)
# Make the ulimit setting persistent across reboots by adding it to /etc/security/limits.conf
echo "* soft nofile $MAX_ULIMIT" >> /etc/security/limits.conf
echo "* hard nofile $MAX_ULIMIT" >> /etc/security/limits.conf

echo "Configuration complete. System modifications applied."
