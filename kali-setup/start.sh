#!/bin/bash
set -euo pipefail

FILEBEAT_CONFIG="/etc/filebeat/filebeat.yml"

info()    { echo -e "\n\033[1;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[1;32m[OK]\033[0m $*"; }
die()     { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run this script with sudo."
[[ -f "$FILEBEAT_CONFIG" ]] || die "filebeat.yml not found at $FILEBEAT_CONFIG. Is filebeat installed?"

# Prompt for nickname
echo ""
echo "  Enter your participant nickname (this will identify your machine in logs):"
read -rp "  Nickname: " NICKNAME

[[ -n "$NICKNAME" ]] || die "Nickname cannot be empty."
[[ "$NICKNAME" =~ ^[a-zA-Z0-9_-]+$ ]] || die "Nickname can only contain letters, numbers, hyphens and underscores."

MACHINE_ID=$(cat /etc/machine-id)

info "Writing participant_id and machine_id to $FILEBEAT_CONFIG..."

sed -i \
  -e "s|participant_id: \".*\"|participant_id: \"${NICKNAME}\"|" \
  -e "s|machine_id: \".*\"|machine_id: \"${MACHINE_ID}\"|" \
  "$FILEBEAT_CONFIG"

info "Checking osqueryd..."
if systemctl is-active --quiet osqueryd; then
  success "osqueryd already running."
else
  info "Starting osqueryd..."
  systemctl start osqueryd
  success "osqueryd started."
fi

info "Restarting filebeat..."
systemctl restart filebeat

success "Done. Logs will be tagged with participant_id: ${NICKNAME}, machine_id: ${MACHINE_ID}"

echo ""
echo "----------------------------------------------"
echo "  Your CTF work folder is at ~/CTF_work_folder"
echo "  Use it while solving challenges."
echo "----------------------------------------------"
echo ""