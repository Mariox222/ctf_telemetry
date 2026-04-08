#!/bin/bash
# =============================================================================
# Kali Host Uninstall Script
# Removes osquery and filebeat and all associated config and log files.
# =============================================================================

set -euo pipefail

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
# STEP 1 - Stop and disable daemons
# =============================================================================

if confirm "Stop and disable filebeat?"; then
  systemctl stop filebeat    2>/dev/null || true
  systemctl disable filebeat 2>/dev/null || true
  success "filebeat stopped and disabled."
else
  skip "filebeat left running."
fi

if confirm "Stop and disable osqueryd?"; then
  systemctl stop osqueryd    2>/dev/null || true
  systemctl disable osqueryd 2>/dev/null || true
  success "osqueryd stopped and disabled."
else
  skip "osqueryd left running."
fi

# =============================================================================
# STEP 2 - Remove filebeat package and apt source
# =============================================================================

if confirm "Remove filebeat package and its apt source?"; then
  apt-get remove --purge -y filebeat 2>/dev/null || true
  rm -f /etc/apt/sources.list.d/elastic-9.x.list
  rm -f /usr/share/keyrings/elasticsearch-keyring.gpg
  apt-get autoremove -y
  success "filebeat package removed."
else
  skip "filebeat package left installed."
fi

# =============================================================================
# STEP 3 - Remove filebeat config and registry
# =============================================================================

if confirm "Remove filebeat config and registry (/etc/filebeat, /var/lib/filebeat)?"; then
  rm -rf /etc/filebeat
  rm -rf /var/lib/filebeat
  success "filebeat config and registry removed."
else
  skip "filebeat config left in place."
fi

# =============================================================================
# STEP 4 - Remove osquery package
# =============================================================================

if confirm "Remove osquery package?"; then
  apt-get remove --purge -y osquery 2>/dev/null || true
  success "osquery package removed."
else
  skip "osquery package left installed."
fi

# =============================================================================
# STEP 5 - Remove osquery config and logs
# =============================================================================

if confirm "Remove osquery config and logs (/etc/osquery, /var/log/osquery)?"; then
  rm -rf /etc/osquery
  rm -rf /var/log/osquery
  success "osquery config and logs removed."
else
  skip "osquery config and logs left in place."
fi

# =============================================================================
# STEP 6 - Remove CTF work folder
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

# filebeat:

# systemctl status filebeat
# filebeat version
# ls /etc/filebeat
# ls /var/lib/filebeat

# osquery:

# systemctl status osqueryd
# osqueryi --version
# ls /etc/osquery
# ls /var/log/osquery
# CTF work folder:

# ls ~/CTF_work_folder