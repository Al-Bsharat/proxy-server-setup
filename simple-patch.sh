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

# Set ulimit to the maximum possible value and make it persistent
MAX_ULIMIT=$(ulimit -Hn)
LIMITS_CONF="/etc/security/limits.conf"

# Remove existing entries to avoid duplicates on re-run
sed -i '/^\*\s\+soft\s\+nofile\s\+/d' "$LIMITS_CONF"
sed -i '/^\*\s\+hard\s\+nofile\s\+/d' "$LIMITS_CONF"
sed -i '/^\*\s\+soft\s\+nproc\s\+/d' "$LIMITS_CONF"
sed -i '/^\*\s\+hard\s\+nproc\s\+/d' "$LIMITS_CONF"

echo "* soft nofile $MAX_ULIMIT" >> "$LIMITS_CONF"
echo "* hard nofile $MAX_ULIMIT" >> "$LIMITS_CONF"
echo "* soft nproc 65535" >> "$LIMITS_CONF"
echo "* hard nproc 65535" >> "$LIMITS_CONF"

# Set systemd default limits (idempotent — only adds if not present)
for conf in /etc/systemd/system.conf /etc/systemd/user.conf; do
    if ! grep -Fxq "DefaultLimitNOFILE=infinity" "$conf"; then
        echo "Adding limits to $conf"
        cat >> "$conf" <<SYSD
DefaultLimitDATA=infinity
DefaultLimitSTACK=infinity
DefaultLimitSIGPENDING=infinity
DefaultLimitCORE=infinity
DefaultLimitRSS=infinity
DefaultLimitNOFILE=infinity
DefaultLimitAS=infinity
DefaultLimitNPROC=infinity
DefaultLimitMEMLOCK=infinity
DefaultTasksMax=infinity
SYSD
    fi
done

echo "Configuration complete. System modifications applied."
