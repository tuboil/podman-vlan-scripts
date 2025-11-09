# podman-vlan-scripts

Scripts et configuration pour gérer les réseaux VLAN Podman sous Ubuntu 24.04+. Ces scripts permettent de créer, gérer et supprimer des réseaux VLAN pour Podman avec une interface en ligne de commande ou un menu interactif.

## Composants

- `/usr/local/bin/podman-vlan` : Outil CLI principal pour gérer les VLANs
- `/usr/local/bin/vlans_interactif_docker_conf.sh` : Interface interactive (TUI)
- `/etc/podman-vlan.conf` : Configuration par défaut (interface réseau, sous-réseaux, etc.)

## Installation

1. Copier les fichiers :
```bash
sudo cp podman-vlan /usr/local/bin/
sudo cp vlans_interactif_docker_conf.sh /usr/local/bin/
sudo cp podman-vlan.conf /etc/
```

2. Rendre les scripts exécutables :
```bash
sudo chmod +x /usr/local/bin/podman-vlan
sudo chmod +x /usr/local/bin/vlans_interactif_docker_conf.sh
```

3. Adapter la configuration (optionnel) :
```bash
sudo nano /etc/podman-vlan.conf
```

## Configuration

Le fichier `/etc/podman-vlan.conf` contient les paramètres par défaut :

```bash
DEFAULT_IFACE="eth0"          # Interface réseau principale
BASE_SUBNET="192.168"         # Préfixe de sous-réseau par défaut
DEFAULT_VLAN_LIST="10 20 30"  # VLANs préconfigurés
TEST_IMAGE="docker.io/library/alpine:latest"  # Image pour tests
TEST_COMMAND="sleep 3600"     # Commande de test
```

## Utilisation

### Interface Interactive

Lancez le menu interactif (requiert root) :
```bash
sudo /usr/local/bin/vlans_interactif_docker_conf.sh
```

Options disponibles dans le menu :
1. Lister VLANs
2. Créer VLAN
3. Supprimer VLAN
4. Recréer VLAN
5. Inspecter VLAN
6. Lancer conteneur de test
7. Basculer dry-run
8. Basculer no-test
9. Basculer verbose

### Ligne de Commande

Le script `podman-vlan` supporte les commandes suivantes :

```bash
# Créer un VLAN
sudo podman-vlan create <VLAN_ID> <SUBNET> [INTERFACE]
# Exemple : sudo podman-vlan create 10 10.10.10.0/24 eth0
# Exemple avec gateway : sudo podman-vlan create 20 192.168.50.0/24 --gateway 192.168.50.254

# Lister les VLANs
sudo podman-vlan list

# Inspecter un VLAN
sudo podman-vlan inspect <VLAN_ID>

# Supprimer un VLAN
sudo podman-vlan delete <VLAN_ID>
```

Options globales :
- `--dry-run` : Affiche les commandes sans les exécuter
- `--no-test` : Ne lance pas de conteneur de test après création
- `--verbose` : Affiche plus de détails
- `--gateway <IP>` : Force une adresse de passerelle spécifique

## Tests et Vérification

Pour tester un VLAN après création :
```bash
# Lancer un conteneur de test
podman run -d --name test_vlan10 --network vlan10 alpine sleep 3600

# Vérifier l'adresse IP
podman exec test_vlan10 ip addr show eth0

# Test de connectivité
podman exec test_vlan10 ping -c 3 <gateway_ip>
```

## Dépannage

### Problèmes Courants

1. "Interface réseau invalide"
   - Vérifiez que l'interface existe : `ip link show`
   - Mettez à jour DEFAULT_IFACE dans la configuration

2. "VLAN existe déjà"
   - Utilisez `podman-vlan delete` pour supprimer l'ancien
   - Ou utilisez `podman-vlan recreate` pour remplacer

3. "Commande requise manquante"
   - Assurez-vous que `ip`, `podman` et les outils réseau sont installés

4. Erreurs de réseau Podman
   - Vérifiez les fichiers CNI : `ls /etc/cni/net.d/`
   - Inspectez les réseaux : `podman network inspect vlan<ID>`

## Sécurité

- Les scripts requièrent des privilèges root
- Assurez-vous que seul root peut modifier les fichiers de configuration
- Validez les sous-réseaux pour éviter les conflits

## Support

Pour les bugs ou suggestions :
1. Ouvrez une issue sur GitHub
2. Incluez la sortie de `podman-vlan list` et `ip addr show`
3. Précisez votre version d'Ubuntu et de Podman

## Cas d'utilisation avancés

Voici quelques exemples / recettes pour des scénarios plus complexes et automatisés.

1) Provisionnement automatisé de plusieurs VLANs

Script shell rapide pour créer une série de VLANs (100-102) avec sous-réseaux et tests :

```bash
#!/usr/bin/env bash
set -euo pipefail
for id in 100 101 102; do
   subnet="10.10.${id}.0/24"
   sudo podman-vlan create "$id" "$subnet" "${DEFAULT_IFACE:-eth0}" --gateway "10.10.${id}.1"
done

# Optionnel : lancer des conteneurs de test pour valider
for id in 100 101 102; do
   sudo podman run -d --name "test_vlan${id}" --network "vlan${id}" alpine sleep 60
done
```

2) Utilisation non-interactive dans un CI / script

Le script interactif nécessite un TTY ; pour automatisation utilisez `podman-vlan` en CLI ou `--dry-run` pour vérifier :

```bash
# dry-run pour revue des commandes sans exécution
sudo podman-vlan --dry-run create 200 192.168.200.0/24 eth0 --gateway 192.168.200.1

# création réelle
sudo podman-vlan create 200 192.168.200.0/24 eth0 --gateway 192.168.200.1
```

3) Recréer proprement un VLAN (delete + create)

```bash
V=200
sudo podman-vlan delete "$V" || true
sudo podman-vlan create "$V" 192.168.200.0/24 eth0 --gateway 192.168.200.1
```

4) Intégration systemd — créer un réseau VLAN au démarrage

Exemple minimal d'un service systemd qui s'assure qu'un VLAN existe au boot :

```
[Unit]
Description=Ensure podman VLAN 200 exists
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/podman-vlan create 200 192.168.200.0/24 eth0
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Enregistrez sous `/etc/systemd/system/podman-vlan-200.service` puis :

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now podman-vlan-200.service
```

5) Ajouter NAT / routage pour accès Internet depuis conteneurs

Si vous souhaitez que les conteneurs des VLANs accèdent à Internet via la machine hôte, activez le forwarding et MASQUERADE :

```bash
sudo sysctl -w net.ipv4.ip_forward=1
sudo iptables -t nat -A POSTROUTING -s 192.168.200.0/24 -o eth0 -j MASQUERADE
```

Pensez à rendre ces règles persistantes (par ex. `iptables-save` / nftables ou via le pare-feu de votre distribution).

6) Sauvegarde / restauration de la configuration CNI

Les fichiers CNI sont générés dans `/etc/cni/net.d/20-vlan<id>.conflist`.
Pour sauvegarder tous les CNI existants :

```bash
sudo tar czf /root/podman-vlan-cni-backup-$(date +%F).tar.gz /etc/cni/net.d/20-vlan*.conflist
```

Pour restaurer :

```bash
sudo tar xzf /root/podman-vlan-cni-backup-2025-11-08.tar.gz -C /
```

7) Bonnes pratiques

- Validez les sous-réseaux pour éviter chevauchements avec votre réseau existant.
- Testez d'abord avec `--dry-run` puis `--no-test` si vous automatisez.
- Conservez une sauvegarde des fichiers CNI avant toute suppression massives.

## Licence

Distribué sous licence MIT. Voir le fichier LICENSE pour plus de détails.
