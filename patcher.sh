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
LIMITS_CONF="/etc/security/limits.conf"
# Remove existing lines matching "* soft nofile ..." or "* hard nofile ..."
sed -i '/^\*\s\+soft\s\+nofile\s\+/d' "$LIMITS_CONF"
sed -i '/^\*\s\+hard\s\+nofile\s\+/d' "$LIMITS_CONF"
# Now add the new lines
echo "* soft nofile $MAX_ULIMIT" >> "$LIMITS_CONF"
echo "* hard nofile $MAX_ULIMIT" >> "$LIMITS_CONF"



if ! grep -Fxq "DefaultLimitDATA=infinity" /etc/systemd/system.conf; then
echo 'Adding /etc/systemd/system.conf settings'
echo "DefaultLimitDATA=infinity
DefaultLimitSTACK=infinity
DefaultLimitSIGPENDING=infinity
DefaultLimitCORE=infinity
DefaultLimitRSS=infinity
DefaultLimitNOFILE=infinity
DefaultLimitAS=infinity
DefaultLimitNPROC=infinity
DefaultLimitMEMLOCK=infinity
DefaultTasksMax=infinity" >> /etc/systemd/system.conf
fi

if ! grep -Fxq "DefaultLimitDATA=infinity" /etc/systemd/user.conf; then
echo 'Adding /etc/systemd/user.conf settings'
echo "DefaultLimitDATA=infinity
DefaultLimitSTACK=infinity
DefaultLimitSIGPENDING=infinity
DefaultLimitCORE=infinity
DefaultLimitRSS=infinity
DefaultLimitNOFILE=infinity
DefaultLimitAS=infinity
DefaultLimitNPROC=infinity
DefaultLimitMEMLOCK=infinity
DefaultTasksMax=infinity" >> /etc/systemd/user.conf
fi

# Update package lists
sudo apt-get update

# Install iptables-persistent to save iptables rules across reboots
# The DEBIAN_FRONTEND=noninteractive flag helps in avoiding interactive prompts
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent

# Block all mail ports from any connection anywhere
# Define common mail ports
MAIL_PORTS=(25 465 587 110 995 143 993)
# Block each port using iptables
for port in "${MAIL_PORTS[@]}"; do
    iptables -A INPUT -p tcp --dport $port -j DROP
    iptables -A OUTPUT -p tcp --dport $port -j DROP
done

# Save iptables rules to make them persistent across reboots
iptables-save > /etc/iptables/rules.v4

echo "Configuration complete. System modifications applied."
