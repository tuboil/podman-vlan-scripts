# podman-vlan-scripts

Scripts and configuration to manage VLAN-backed Podman networks on Ubuntu 24.04.

Included:
- `/usr/local/bin/podman-vlan` : CLI to create/delete/list/inspect VLAN networks for Podman.
- `/usr/local/bin/vlans_interactif_docker_conf.sh` : interactive menu wrapper for `podman-vlan`.
- `/etc/podman-vlan.conf` : default configuration.

Usage:
Run the interactive menu (requires root):

```bash
sudo /usr/local/bin/vlans_interactif_docker_conf.sh
```

Or use the CLI directly:

```bash
sudo podman-vlan create <VLAN_ID> <SUBNET> [INTERFACE]
sudo podman-vlan list
sudo podman-vlan delete <VLAN_ID>
```

Notes:
- The interactive script now checks for a TTY and will exit with a clear message when run in non-interactive environments.
- This repository contains the state imported from the machine; review scripts before using in production.

