#!/bin/bash
# Script 02 : Install K3S (Master or Worker)
# Usage: 
#   Master:  sudo ./02_install_k3s.sh master
#   Worker:  sudo ./02_install_k3s.sh worker <MASTER_IP> <TOKEN>

set -e

MODE=${1:-master}
MASTER_IP=${2:-}
TOKEN=${3:-}

echo "========================================"
echo "K3S Installation - Mode: $MODE"
echo "========================================"

if [ "$MODE" = "master" ]; then
  echo "[*] Installing K3S Server (Master)..."
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="" sh -
  
  echo ""
  echo "✅ Master K3S installed successfully!"
  echo ""
  echo "To join workers, use:"
  TOKEN=$(sudo cat /var/lib/rancher/k3s/server/node-token)
  MASTER_IP=$(hostname -I | awk '{print $1}')
  echo "  Master IP: $MASTER_IP"
  echo "  Token: $TOKEN"
  echo "  Command: ./02_install_k3s.sh worker $MASTER_IP $TOKEN"
  
  echo ""
  echo "Waiting for cluster to be ready..."
  sleep 10
  
  echo "[*] Cluster nodes:"
  sudo k3s kubectl get nodes -o wide
  
elif [ "$MODE" = "worker" ]; then
  if [ -z "$MASTER_IP" ] || [ -z "$TOKEN" ]; then
    echo "❌ Error: Missing MASTER_IP or TOKEN"
    echo "Usage: sudo ./02_install_k3s.sh worker <MASTER_IP> <TOKEN>"
    exit 1
  fi
  
  echo "[*] Installing K3S Agent (Worker)..."
  echo "    Master: $MASTER_IP:6443"
  
  export K3S_URL="https://$MASTER_IP:6443"
  export K3S_TOKEN="$TOKEN"
  
  curl -sfL https://get.k3s.io | sh -
  
  echo ""
  echo "✅ Worker K3S installed successfully!"
  echo ""
  echo "Waiting for node to be ready..."
  sleep 5
  
  echo "[*] Node status:"
  ssh -o StrictHostKeyChecking=no "$MASTER_IP" "sudo k3s kubectl get nodes -o wide"
  
else
  echo "❌ Invalid mode: $MODE"
  echo "Usage:"
  echo "  Master: sudo ./02_install_k3s.sh master"
  echo "  Worker: sudo ./02_install_k3s.sh worker <MASTER_IP> <TOKEN>"
  exit 1
fi
