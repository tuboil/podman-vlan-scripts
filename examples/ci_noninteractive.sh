#!/usr/bin/env bash
set -euo pipefail

# Example non-interactive usage suitable for CI pipelines
# Usage: ./ci_noninteractive.sh

VLAN=200
SUBNET=192.168.200.0/24
IFACE=${1:-eth0}

echo "Dry-run creation (for CI review)"
sudo podman-vlan --dry-run create "$VLAN" "$SUBNET" "$IFACE" --gateway 192.168.200.1

echo "Create for real"
sudo podman-vlan create "$VLAN" "$SUBNET" "$IFACE" --gateway 192.168.200.1

echo "Done"
