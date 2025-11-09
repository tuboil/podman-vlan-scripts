# Examples for podman-vlan-scripts

This directory contains ready-to-run example scripts and snippets demonstrating advanced use-cases described in the main README.

Files:
- `provision_vlans.sh` : create multiple VLANs programmatically
- `ci_noninteractive.sh` : example using the CLI in CI/fixed scripts
- `recreate_vlan.sh` : delete then create a VLAN safely
- `nat_setup.sh` : enable IP forwarding and iptables MASQUERADE
- `backup_cni.sh` : backup/restore of CNI configuration files
- `systemd/podman-vlan-200.service` : example systemd unit

Make scripts executable before using them:

```bash
chmod +x examples/*.sh
```

Run and adapt them to your environment. They are provided as examples—review before using in production.
