#!/usr/bin/env bash
set -euo pipefail

# Backup CNI files for all VLANs
# Usage: sudo ./backup_cni.sh [dest]

DEST=${1:-/root}
OUT=${DEST}/podman-vlan-cni-backup-$(date +%F).tar.gz

echo "Backing up /etc/cni/net.d/20-vlan*.conflist -> ${OUT}"
sudo tar czf "${OUT}" /etc/cni/net.d/20-vlan*.conflist

echo "Backup written to ${OUT}"
