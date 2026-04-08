#!/bin/bash
# =============================================================================
# Kali Host Setup Script
# Sets up osquery + filebeat on a fresh Kali Linux VM for CTF telemetry.
#
# Starting image: kali-linux-2025.4-virtualbox-amd64
#
# Before running:
#   1. Edit filebeat-template.yml with the server IP and filebeat_user password
#   2. Place all required files in the same directory as this script (see preflight)
#   3. chmod +x install.sh
#   4. sudo ./install.sh
#
# After running, see README for optional manual steps (keyboard layout, VS Code).
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OSQUERY_DEB="osquery_5.21.0-1.linux_amd64.deb"
MACADMINS_EXT="macadmins_extension.amd64.ext"
REAL_HOME=$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)
CTF_WORK_FOLDER="$REAL_HOME/CTF_work_folder"

# =============================================================================
# HELPERS
# =============================================================================

info()    { echo -e "\n\033[1;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[1;32m[OK]\033[0m $*"; }
warn()    { echo -e "\033[1;33m[WARN]\033[0m $*"; }
die()     { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

# =============================================================================
# PREFLIGHT
# =============================================================================

info "Checking required files..."

[[ -f "$SCRIPT_DIR/$OSQUERY_DEB" ]] \
  || die "$OSQUERY_DEB not found in $SCRIPT_DIR. Download it before running."

[[ -f "$SCRIPT_DIR/$MACADMINS_EXT" ]] \
  || die "$MACADMINS_EXT not found in $SCRIPT_DIR. Extract it from the macadmins zip before running."

[[ -f "$SCRIPT_DIR/osquery.conf" ]] \
  || die "osquery.conf not found in $SCRIPT_DIR."

[[ -f "$SCRIPT_DIR/osquery.flags" ]] \
  || die "osquery.flags not found in $SCRIPT_DIR."

[[ -f "$SCRIPT_DIR/filebeat-template.yml" ]] \
  || die "filebeat-template.yml not found in $SCRIPT_DIR. Edit it with server IP and password before running."

success "All required files found."

# =============================================================================
# STEP 1 - System update and full upgrade
# =============================================================================

read -rp "$(echo -e "\033[1;34m[INFO]\033[0m Run system update and full upgrade? [y/N]: ")" ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
  info "Updating and upgrading system..."
  apt-get update -y
  apt-get full-upgrade -y
  success "System up to date."
else
  warn "Skipping system update."
fi

# =============================================================================
# STEP 2 - Install osquery
# =============================================================================

info "Installing osquery..."
apt-get install -y "$SCRIPT_DIR/$OSQUERY_DEB"
success "osquery installed: $(osqueryi --version)"

# =============================================================================
# STEP 3 - Copy osquery config files
# =============================================================================

info "Copying osquery config files..."

# These files don't exist by default after osquery install
touch /etc/osquery/osquery.flags
touch /etc/osquery/osquery.conf

cp "$SCRIPT_DIR/osquery.conf"  /etc/osquery/osquery.conf
cp "$SCRIPT_DIR/osquery.flags" /etc/osquery/osquery.flags

success "osquery.conf and osquery.flags copied."

# =============================================================================
# STEP 4 - Install macadmins osquery extension
# =============================================================================

info "Installing macadmins osquery extension..."

cp "$SCRIPT_DIR/$MACADMINS_EXT" /etc/osquery/$MACADMINS_EXT
chmod +x /etc/osquery/$MACADMINS_EXT

success "macadmins extension copied to /etc/osquery/"

# =============================================================================
# STEP 5 - Set log file permissions
# =============================================================================

info "Configuring osquery log permissions..."

# Start osqueryd briefly to ensure the log file is created before chmod
systemctl start osqueryd || true
sleep 2
systemctl stop osqueryd || true

# Give all users read access so filebeat can read the log without root
chmod o+r /var/log/osquery/osqueryd.results.log 2>/dev/null || true

success "Read access granted to /var/log/osquery/osqueryd.results.log"

# =============================================================================
# STEP 6 - Install filebeat
# =============================================================================

info "Installing filebeat..."

wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch \
  | gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] \
  https://artifacts.elastic.co/packages/9.x/apt stable main" \
  | tee /etc/apt/sources.list.d/elastic-9.x.list > /dev/null
apt-get update -y
apt-get install -y filebeat=9.3.1

success "filebeat installed: $(filebeat version)"

# =============================================================================
# STEP 7 - Configure filebeat
# =============================================================================

info "Configuring filebeat..."

cp "$SCRIPT_DIR/filebeat-template.yml" /etc/filebeat/filebeat.yml

# Clear registry so filebeat ships all logs fresh on first start
rm -rf /var/lib/filebeat/registry

success "filebeat.yml installed and registry cleared."

# =============================================================================
# STEP 8 - Create CTF work folder
# =============================================================================

info "Creating CTF work folder..."
mkdir -p "$CTF_WORK_FOLDER"
chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$CTF_WORK_FOLDER"
success "CTF_work_folder created at $CTF_WORK_FOLDER"

# =============================================================================
# STEP 9 - Enable and start daemons
# =============================================================================

info "Enabling and starting osqueryd..."
systemctl enable osqueryd
systemctl restart osqueryd
success "osqueryd running."

info "Enabling and starting filebeat..."
systemctl enable filebeat
systemctl restart filebeat
success "filebeat running."

# =============================================================================
# DONE
# =============================================================================

echo ""
echo "=============================================="
echo "  Kali host setup complete!"
echo "=============================================="
echo ""
echo "  osqueryd  : $(systemctl is-active osqueryd)"
echo "  filebeat  : $(systemctl is-active filebeat)"
echo ""
echo "  Check osquery daemon status"
echo "    sudo systemctl status osqueryd"
echo ""
echo "  Verify filebeat can reach the server:"
echo "    sudo filebeat test output"
echo ""
echo "  Watch live filebeat logs:"
echo "    sudo journalctl -u filebeat -f"
echo ""
# "----------------------------------------------"
# "  Further recommended:"
# ""
# "  1. Croatian keyboard layout:"
# "       Settings -> Keyboard -> Add layout -> Croatian"
# ""
# "  2. VS Code:"
# "       Download from https://code.visualstudio.com"
# "       sudo apt install ./code_*.deb"
# "----------------------------------------------"
# ""