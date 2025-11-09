#!/usr/bin/env bash
set -euo pipefail

# Enable IP forwarding and add MASQUERADE for a subnet
# Usage: sudo ./nat_setup.sh 192.168.200.0/24 eth0

SUBNET=${1:-192.168.200.0/24}
OUT_IF=${2:-eth0}

echo "Enabling IPv4 forwarding"
sudo sysctl -w net.ipv4.ip_forward=1

echo "Adding iptables MASQUERADE for ${SUBNET} -> ${OUT_IF}"
sudo iptables -t nat -A POSTROUTING -s "${SUBNET}" -o "${OUT_IF}" -j MASQUERADE

echo "Done. Remember to persist iptables/nft rules if needed."
