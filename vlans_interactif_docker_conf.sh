#!/usr/bin/env bash
# ==========================================================
# Script interactif de gestion VLANs Podman
# Version 2.2 - avec relance automatique sudo et main fixe
# Compatible avec podman-vlan v2.1+
# ==========================================================

set -euo pipefail

# --- Relance automatique avec sudo ---
if [[ "$EUID" -ne 0 ]]; then
  echo "[INFO] Relance du script avec sudo..."
  exec sudo bash "$0" "$@"
fi

# Vérifier si on a un terminal interactif (stdin TTY). Si non, afficher un message clair
# et quitter avec un code spécifique. Cela évite que le script se termine silencieusement
# lorsqu'il est lancé dans un environnement non-interactif (ex: job, runner).
if [[ ! -t 0 ]]; then
  echo "[ERROR] Ce script requiert un terminal interactif (TTY). Lancez-le directement dans un shell, ex: sudo /usr/local/bin/vlans_interactif_docker_conf.sh" >&2
  exit 2
fi

# --- Couleurs ---
GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; BLUE="\e[34m"; RESET="\e[0m"
log()   { echo -e "${GREEN}$*${RESET}"; }
warn()  { echo -e "${YELLOW}$*${RESET}"; }
error() { echo -e "${RED}$*${RESET}" >&2; exit 1; }
info()  { echo -e "${BLUE}$*${RESET}"; }

# --- Variables globales ---
DEFAULT_IFACE=""
CONF_FILE="/etc/podman-vlan.conf"
PODMAN_VLAN_BIN="podman-vlan"
DRY_RUN=false
NO_TEST=false
VERBOSE=false
BASE_SUBNET="192.168"
DEFAULT_VLAN_LIST=()
TEST_IMAGE="docker.io/library/alpine:latest"
TEST_COMMAND="sleep 3600"

# --- Charger configuration (si dispo) ---
load_config() {
  if [[ -f "$CONF_FILE" ]]; then
    # shellcheck source=/etc/podman-vlan.conf
    source "$CONF_FILE"
  fi
}

# --- Vérifications environnement ---
check_env() {
  for cmd in ip podman "$PODMAN_VLAN_BIN"; do
    command -v "$cmd" >/dev/null 2>&1 || error "Commande requise manquante : $cmd"
  done
}

# --- Détecter interface ---
detect_iface() {
  DEFAULT_IFACE=$(ip route | awk '/default/ {print $5; exit}')
  # Utiliser un bloc if explicite pour éviter tout comportement inattendu
  # avec 'set -e' et les listes conditionnelles.
  if [[ -z "${DEFAULT_IFACE:-}" ]]; then
    DEFAULT_IFACE="eth0"
  fi
}

# --- Fonction d’appel avec modes dynamiques ---
run_vlan_cmd() {
  local cmd=("sudo" "$PODMAN_VLAN_BIN")
  [[ "$VERBOSE" == true ]] && cmd+=("--verbose")
  [[ "$DRY_RUN" == true ]] && cmd+=("--dry-run")
  [[ "$NO_TEST" == true ]] && cmd+=("--no-test")
  "${cmd[@]}" "$@"
}

# ==========================================================
# Sous-menus
# ==========================================================

menu_create_vlan() {
  read -r -p "ID VLAN (1-4094) : " VLAN_ID
  read -r -p "Sous-réseau (ex: ${BASE_SUBNET}.${VLAN_ID}.0/24) [Entrée=auto] : " SUBNET
  [[ -z "$SUBNET" ]] && SUBNET="${BASE_SUBNET}.${VLAN_ID}.0/24"
  read -r -p "Interface [${DEFAULT_IFACE}] : " IFACE
  [[ -z "$IFACE" ]] && IFACE="${DEFAULT_IFACE}"
  read -r -p "Passerelle (Entrée=auto) : " GW
  local args=("create" "$VLAN_ID" "$SUBNET" "$IFACE")
  [[ -n "$GW" ]] && args+=("--gateway" "$GW")
  run_vlan_cmd "${args[@]}"
}

menu_delete_vlan() {
  read -r -p "ID VLAN à supprimer : " VLAN_ID
  run_vlan_cmd delete "$VLAN_ID"
}

menu_recreate_vlan() {
  read -r -p "ID VLAN à recréer : " VLAN_ID
  read -r -p "Sous-réseau (ex: ${BASE_SUBNET}.${VLAN_ID}.0/24) [Entrée=auto] : " SUBNET
  [[ -z "$SUBNET" ]] && SUBNET="${BASE_SUBNET}.${VLAN_ID}.0/24"
  read -r -p "Interface [${DEFAULT_IFACE}] : " IFACE
  [[ -z "$IFACE" ]] && IFACE="${DEFAULT_IFACE}"
  read -r -p "Passerelle (Entrée=auto) : " GW
  run_vlan_cmd delete "$VLAN_ID" || true
  local args=("create" "$VLAN_ID" "$SUBNET" "$IFACE")
  [[ -n "$GW" ]] && args+=("--gateway" "$GW")
  run_vlan_cmd "${args[@]}"
}

menu_list_vlans() {
  run_vlan_cmd list
}

menu_inspect_vlan() {
  read -r -p "ID VLAN à inspecter : " VLAN_ID
  run_vlan_cmd inspect "$VLAN_ID"
}

menu_test_container() {
  read -r -p "ID VLAN pour test : " VLAN_ID
  log "Lancement d'un conteneur de test sur VLAN $VLAN_ID ..."
  podman run -d --name "test_vlan${VLAN_ID}" --network "vlan${VLAN_ID}" "$TEST_IMAGE" $TEST_COMMAND
  log "Conteneur lancé (nom : test_vlan${VLAN_ID})"
}

# ==========================================================
# Bascules dynamiques
# ==========================================================
menu_toggle_dry_run() {
  DRY_RUN=$([[ "$DRY_RUN" == true ]] && echo false || echo true)
  log "Mode dry-run : ${DRY_RUN^^}"
}
menu_toggle_no_test() {
  NO_TEST=$([[ "$NO_TEST" == true ]] && echo false || echo true)
  log "Mode no-test : ${NO_TEST^^}"
}
menu_toggle_verbose() {
  VERBOSE=$([[ "$VERBOSE" == true ]] && echo false || echo true)
  log "Mode verbose : ${VERBOSE^^}"
}

# ==========================================================
# Menu principal
# ==========================================================
show_menu() {
  while true; do
    echo
    echo -e "${BLUE}=== MENU VLANs Podman ===${RESET}"
    echo "Interface par défaut : $DEFAULT_IFACE"
    echo "Modes actifs : dry-run=${DRY_RUN}, no-test=${NO_TEST}, verbose=${VERBOSE}"
    echo
    echo "1) Lister VLANs"
    echo "2) Créer VLAN"
    echo "3) Supprimer VLAN"
    echo "4) Recréer VLAN"
    echo "5) Inspecter VLAN"
    echo "6) Lancer conteneur de test"
    echo "7) Basculer dry-run"
    echo "8) Basculer no-test"
    echo "9) Basculer verbose"
    echo "0) Quitter"
    echo
    read -r -p "Choix : " CHOICE
    case "$CHOICE" in
      1) menu_list_vlans ;;
      2) menu_create_vlan ;;
      3) menu_delete_vlan ;;
      4) menu_recreate_vlan ;;
      5) menu_inspect_vlan ;;
      6) menu_test_container ;;
      7) menu_toggle_dry_run ;;
      8) menu_toggle_no_test ;;
      9) menu_toggle_verbose ;;
      0) log "Sortie."; exit 0 ;;
      *) warn "Choix invalide." ;;
    esac
  done
}

# ==========================================================
# Main
# ==========================================================
main() {
  load_config
  check_env
  detect_iface
  info "Interface détectée : ${DEFAULT_IFACE}"
  info "Configuration chargée depuis : ${CONF_FILE} (si présent)"
  show_menu
}

main "$@"

