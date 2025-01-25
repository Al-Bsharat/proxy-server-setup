#!/usr/bin/env bash

# fix_sudo.sh
# This script attempts to fix common sudo issues, such as:
# 1) Hostname resolution errors.
# 2) Missing or empty /etc/hosts entries.
# 3) Missing sudo installation.
# 4) Current user lacking sudo privileges.

set -e

# 1. Check for root privileges or use sudo when needed
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script with sudo or as root."
  exit 1
fi

# 2. Ensure sudo is installed
if ! command -v sudo &> /dev/null; then
  echo "sudo is not installed. Installing now..."
  apt-get update -y
  apt-get install sudo -y
  echo "sudo has been installed successfully."
fi

# 3. Fix or populate /etc/hosts if empty or missing essential lines
HOSTS_FILE="/etc/hosts"
if [ ! -s "$HOSTS_FILE" ]; then
  echo "/etc/hosts is empty or missing. Adding default entries..."
  cat <<EOF > "$HOSTS_FILE"
127.0.0.1   localhost
::1         ip6-localhost ip6-loopback
fe00::0     ip6-localnet
ff00::0     ip6-mcastprefix
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF
  echo "Default entries added to /etc/hosts."
fi

# 4. Ensure the current hostname is in /etc/hosts
CURRENT_HOSTNAME=$(hostname)
if ! grep -q "$CURRENT_HOSTNAME" "$HOSTS_FILE"; then
  echo "Hostname '$CURRENT_HOSTNAME' not found in /etc/hosts. Adding it now..."
  # Use 127.0.1.1 for Debian/Ubuntu-based systems
  echo "127.0.1.1   $CURRENT_HOSTNAME" >> "$HOSTS_FILE"
  echo "Hostname entry added to /etc/hosts."
fi

# 5. Ensure the current user is part of the sudo group
#    (Adjust group name for other distros, e.g., 'wheel' on CentOS)
CURRENT_USER=$(logname 2>/dev/null || echo "$SUDO_USER")
if [ -z "$CURRENT_USER" ] || [ "$CURRENT_USER" = "root" ]; then
  echo "Skipped adding user to sudo group because the current user is root or undefined."
else
  if ! id -nG "$CURRENT_USER" | grep -qw "sudo"; then
    echo "Adding user '$CURRENT_USER' to the sudo group..."
    usermod -aG sudo "$CURRENT_USER"
    echo "User '$CURRENT_USER' has been added to the sudo group."
    echo "You may need to re-login or reboot for this to take effect."
  else
    echo "User '$CURRENT_USER' is already in the sudo group."
  fi
fi

echo
echo "=== Summary of Changes ==="
echo "1) Ensured 'sudo' is installed."
echo "2) Populated /etc/hosts if it was empty."
echo "3) Added hostname '$CURRENT_HOSTNAME' if it was missing."
echo "4) Checked or added the current user to the 'sudo' group."
echo
echo "All done. If you still experience issues, please log out and log back in, or reboot."
