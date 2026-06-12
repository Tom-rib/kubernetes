#!/bin/bash
# Script 01 : Configuration VM Debian Trixie pour K3S
# Usage: sudo ./01_setup_debian.sh
# Tested on: Debian Trixie (Testing)

set -e  # Exit on error

echo "========================================"
echo "K3S Configuration for Debian Trixie"
echo "========================================"

# 1. System updates
echo "[*] Updating system packages..."
sudo apt update
sudo apt upgrade -y
sudo apt install -y \
  curl wget git vim htop net-tools \
  nftables ca-certificates apt-transport-https \
  linux-headers-$(uname -r)

# 2. Load kernel modules
echo "[*] Loading kernel modules..."
sudo modprobe br_netfilter
sudo modprobe overlay

# Persist modules at boot
echo "br_netfilter" | sudo tee /etc/modules-load.d/k3s.conf > /dev/null
echo "overlay" | sudo tee -a /etc/modules-load.d/k3s.conf > /dev/null

# 3. Configure sysctl
echo "[*] Configuring sysctl for K3S..."
sudo tee /etc/sysctl.d/99-k3s.conf > /dev/null << EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.all.rp_filter = 0
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
EOF

sudo sysctl -p /etc/sysctl.d/99-k3s.conf > /dev/null

# 4. Configure nftables (Debian Trixie uses nftables instead of iptables-legacy)
echo "[*] Configuring nftables firewall..."
sudo tee /etc/nftables.conf > /dev/null << 'EOF'
#!/usr/bin/nft -f

flush ruleset

table inet filter {
  chain input {
    type filter hook input priority filter; policy accept;
    
    # Loopback
    iifname lo accept
    
    # Established connections
    ct state established,related accept
    
    # ICMP (ping)
    ip protocol icmp accept
    ipv6 nexthdr icmpv6 accept
    
    # SSH (22)
    tcp dport 22 accept
    
    # K3S API Server (6443)
    tcp dport 6443 accept
    
    # Kubelet (10250)
    tcp dport 10250 accept
    
    # K3S Service NodePort range (30000-32767)
    tcp dport 30000-32767 accept
    udp dport 30000-32767 accept
    
    # Flannel VXLAN (8472)
    udp dport 8472 accept
    
    # CoreDNS (53)
    tcp dport 53 accept
    udp dport 53 accept
    
    # Drop everything else
    reject with icmp type port-unreachable
  }
  
  chain forward {
    type filter hook forward priority filter; policy accept;
  }
  
  chain output {
    type filter hook output priority filter; policy accept;
  }
}
EOF

# Enable and restart nftables
sudo systemctl enable nftables
sudo systemctl restart nftables

# 5. Disable swap
echo "[*] Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# 6. Verify configuration
echo ""
echo "========================================"
echo "✅ Configuration Complete!"
echo "========================================"
echo ""
echo "Verification:"
echo "  Kernel modules: $(lsmod | grep -E 'br_netfilter|overlay' | wc -l) loaded"
echo "  IP forwarding: $(sysctl net.ipv4.ip_forward | cut -d= -f2 | xargs)"
echo "  nftables: $(sudo systemctl is-active nftables)"
echo "  Swap: $(grep 'SwapTotal' /proc/meminfo | awk '{print $2}') KB"
echo ""
echo "Next step: Install K3S (02_install_k3s.sh)"
