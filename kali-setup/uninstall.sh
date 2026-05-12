#!/bin/bash
# =============================================================================
# Kali Host Uninstall Script
# Removes osquery and filebeat and all associated config and log files.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACADMINS_EXT="macadmins_extension.amd64.ext"
REAL_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
CTF_WORK_FOLDER="$REAL_HOME/CTF_work_folder"

info()    { echo -e "\n\033[1;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[1;32m[OK]\033[0m $*"; }
skip()    { echo -e "\033[1;33m[SKIP]\033[0m $*"; }

confirm() {
  read -rp "$1 [y/N]: " ans
  [[ "$ans" =~ ^[Yy]$ ]]
}

[[ $EUID -eq 0 ]] || { echo "Run this script with sudo."; exit 1; }

# =============================================================================
# STEP 1 - Stop and remove filebeat container
# =============================================================================

if confirm "Stop and remove filebeat Docker container?"; then
  docker compose -f "$SCRIPT_DIR/docker-compose.yml" down -v 2>/dev/null || true
  success "filebeat container stopped and removed."
else
  skip "filebeat container left running."
fi

# =============================================================================
# STEP 2 - Stop and disable osqueryd
# =============================================================================

if confirm "Stop and disable osqueryd?"; then
  systemctl stop osqueryd    2>/dev/null || true
  systemctl disable osqueryd 2>/dev/null || true
  success "osqueryd stopped and disabled."
else
  skip "osqueryd left running."
fi

# =============================================================================
# STEP 3 - Remove osquery package
# =============================================================================

if confirm "Remove osquery package?"; then
  apt-get remove --purge -y osquery 2>/dev/null || true
  success "osquery package removed."
else
  skip "osquery package left installed."
fi

# =============================================================================
# STEP 4 - Remove osquery config and logs
# =============================================================================

if confirm "Remove osquery config and logs (/etc/osquery, /var/log/osquery)?"; then
  rm -rf /etc/osquery
  rm -rf /var/log/osquery
  success "osquery config and logs removed."
else
  skip "osquery config and logs left in place."
fi

# =============================================================================
# STEP 5 - Remove CTF work folder
# =============================================================================

if confirm "Remove CTF work folder ($CTF_WORK_FOLDER)?"; then
  rm -rf "$CTF_WORK_FOLDER"
  success "CTF work folder removed."
else
  skip "CTF work folder left in place."
fi

# =============================================================================
# DONE
# =============================================================================

echo ""
echo "=============================================="
echo "  Uninstall complete."
echo "=============================================="
echo ""
