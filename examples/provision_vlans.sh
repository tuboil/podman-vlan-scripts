#!/usr/bin/env bash
set -euo pipefail

# Provision multiple VLANs (example)
# Usage: sudo ./provision_vlans.sh

DEFAULT_IFACE="${DEFAULT_IFACE:-eth0}"
for id in 100 101 102; do
  subnet="10.10.${id}.0/24"
  echo "Creating VLAN ${id} -> ${subnet} on ${DEFAULT_IFACE}"
  sudo podman-vlan create "$id" "$subnet" "$DEFAULT_IFACE" --gateway "10.10.${id}.1"
done

echo "Optionally launching test containers..."
for id in 100 101 102; do
  sudo podman run -d --name "test_vlan${id}" --network "vlan${id}" docker.io/library/alpine:latest sleep 60 || true
done

echo "Done."
