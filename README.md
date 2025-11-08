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

## Licence

Distribué sous licence MIT. Voir le fichier LICENSE pour plus de détails.
