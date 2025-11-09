#!/usr/bin/env bash
set -euo pipefail

# Recreate a VLAN safely (delete if exists, then create)
# Usage: sudo ./recreate_vlan.sh <VLAN_ID>

if [ $# -lt 1 ]; then
  echo "Usage: $0 <VLAN_ID>"
  exit 2
fi

VLAN=$1
SUBNET=${2:-192.168.${VLAN}.0/24}
IFACE=${3:-eth0}

echo "Recreating VLAN $VLAN"
sudo podman-vlan delete "$VLAN" || true
sudo podman-vlan create "$VLAN" "$SUBNET" "$IFACE"

echo "Done"
