#!/bin/bash
# Script 05 : Test High Availability features
# Usage: ./05_test_ha.sh

set -e

echo "========================================"
echo "K3S High Availability Tests"
echo "========================================"

MASTER="kubes-01.local"

# 1. Test: Delete a pod and check self-healing
echo ""
echo "[TEST 1] Self-healing: Deleting a Nginx pod..."
POD=$(sudo k3s kubectl get pods -l app=nginx -o jsonpath='{.items[0].metadata.name}')
echo "  Deleting pod: $POD"
sudo k3s kubectl delete pod $POD
echo "  Waiting 10 seconds for replacement..."
sleep 10
echo "  New pods:"
sudo k3s kubectl get pods -l app=nginx

# 2. Test: Load balancing across replicas
echo ""
echo "[TEST 2] Load balancing (hitting same service 10 times)..."
for i in {1..10}; do
  echo "  Request $i:"
  curl -s http://localhost:30080 | head -n 1
done

# 3. Test: Check ReplicaSet
echo ""
echo "[TEST 3] ReplicaSet status..."
sudo k3s kubectl get rs | grep nginx

# 4. Test: Node drain and reschedule
echo ""
echo "[TEST 4] Checking pod distribution across nodes..."
sudo k3s kubectl get pods -o wide | grep -E 'nginx|apache'

# 5. Test: Simulate node maintenance
echo ""
echo "[TEST 5] Testing node drain (simulated)..."
echo "  To drain a node: sudo k3s kubectl drain <NODE_NAME> --ignore-daemonsets --delete-emptydir-data"
echo "  Then: sudo k3s kubectl uncordon <NODE_NAME>"

# 6. Verify events
echo ""
echo "[TEST 6] Recent cluster events..."
sudo k3s kubectl get events --sort-by='.lastTimestamp' | tail -10

echo ""
echo "========================================"
echo "✅ HA Tests completed!"
echo "========================================"
