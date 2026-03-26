#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Stop and disable systemd-resolved
systemctl stop systemd-resolved
systemctl disable systemd-resolved

# Remove the symlink to /run/systemd/resolve/stub-resolv.conf
rm -f /etc/resolv.conf

# Create new resolv.conf with Cloudflare DNS (IPv4 and IPv6)
cat > /etc/resolv.conf <<EOL
# Cloudflare DNS resolvers
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 2606:4700:4700::1111
nameserver 2606:4700:4700::1001
options edns0
EOL

# Make resolv.conf immutable to prevent system from modifying it
chattr +i /etc/resolv.conf

# Download the configuration file and place it in /etc/sysctl.d/
wget -O /etc/sysctl.d/99-custom.conf https://raw.githubusercontent.com/Al-Bsharat/proxy-server-setup/main/99-custom.conf

# Reload system-wide sysctl settings
sysctl --system

# Set nofile limits for login sessions and systemd services.
MAX_ULIMIT=$(ulimit -Hn)
mkdir -p /etc/security/limits.d
cat > /etc/security/limits.d/99-proxy-nofile.conf <<EOF
* soft nofile $MAX_ULIMIT
* hard nofile $MAX_ULIMIT
EOF

mkdir -p /etc/systemd/system.conf.d
cat > /etc/systemd/system.conf.d/99-proxy-nofile.conf <<EOF
[Manager]
DefaultLimitNOFILE=$MAX_ULIMIT
EOF

systemctl daemon-reexec

# Update package lists
apt-get update

# Install iptables-persistent to save iptables rules across reboots
DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent

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
