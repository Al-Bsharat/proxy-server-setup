# Proxy Server Setup Script

## Overview

This project provides a simple yet powerful script designed to prepare and patch an Ubuntu server for use as a proxy server. The script automates the configuration of system settings and network rules to optimize the server's performance and security for proxy server operations.

Key actions performed by the script include:
- Downloading and applying a custom sysctl configuration to optimize network performance.
- Setting the maximum number of open file descriptors to enhance the server's ability to handle a large number of concurrent connections.
- Blocking all mail ports to improve security and prevent misuse of the server for sending unsolicited emails.
- Installing `iptables-persistent` to ensure firewall rules persist across reboots.

### Production notes

- The sysctl profile now keeps ephemeral ports in `10000-65535`. This avoids low service ports and gives a large outbound port pool.
- If your proxy listens on any ports inside that range, edit `/etc/sysctl.d/99-custom.conf` and set `net.ipv4.ip_local_reserved_ports` for those listener ports before heavy production use.
- Sysctl alone cannot fully prevent ephemeral port exhaustion for applications that `bind()` a source IP before `connect()`. Those applications should also enable Linux `IP_BIND_ADDRESS_NO_PORT` on outbound sockets.
- Removed dangerous hard-coded TCP/UDP memory values so the kernel can auto-tune those for the host.
- `tcp_max_tw_buckets` set to 2,000,000 for high-churn forward proxies. The kernel default varies by distro/RAM but is often too low when connecting to millions of unique destination IPs.
- `tcp_no_metrics_save` enabled — beneficial when the host mostly connects to unique one-off destinations (forward proxies, scrapers) where cached metrics are rarely reused. Disable this (set to 0) if your workload repeatedly reconnects to the same small set of servers.

### Notes

The scripts now install `nofile` defaults through `/etc/security/limits.d/99-proxy-nofile.conf` and `/etc/systemd/system.conf.d/99-proxy-nofile.conf`. For the most predictable production setup, still set `LimitNOFILE=1048576` (or your chosen value) in the proxy's own systemd unit so the service carries an explicit per-service override.

### Installation

To apply the patch to your server, execute the following command in your terminal. This command downloads the script and executes it with root privileges. Ensure you have the necessary permissions to perform these actions on your server.

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Al-Bsharat/proxy-server-setup/main/patcher.sh)"
```

Without SMTP block:
```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/Al-Bsharat/proxy-server-setup/main/simple-patch.sh)"
```
### Prerequisites

- An Ubuntu server (The script is designed with Ubuntu in mind, but it may work with slight modifications on other Linux distributions.)
- Root access to the server.
- `curl` installed on the server (for downloading the script).
