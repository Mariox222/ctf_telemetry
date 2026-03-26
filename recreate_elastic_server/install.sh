#!/bin/bash
# =============================================================================
# Elasticsearch + Kibana Setup Script
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$HOME/elastic-lab"

# =============================================================================
# HELPERS
# =============================================================================

info()    { echo -e "\n\033[1;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[1;32m[OK]\033[0m $*"; }
warn()    { echo -e "\033[1;33m[WARN]\033[0m $*"; }
die()     { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

# =============================================================================
# PREFLIGHT — check required files exist
# =============================================================================

info "Checking required files..."

[[ -f "$SCRIPT_DIR/.env" ]] \
  || die ".env not found in $SCRIPT_DIR. Create it before running."

[[ -f "$SCRIPT_DIR/docker-compose.yml" ]] \
  || die "docker-compose.yml not found in $SCRIPT_DIR. Create it before running."

success ".env and docker-compose.yml found."

# =============================================================================
# PREFLIGHT — read and validate .env
# =============================================================================

info "Reading .env..."
export $(grep -v '^#' "$SCRIPT_DIR/.env" | xargs)

DEFAULT="REPLACE_WITH_STRONG_PASSWORD"
MISSING=()

[[ "${ELASTIC_PASSWORD:-}"       == "$DEFAULT" || -z "${ELASTIC_PASSWORD:-}"       ]] && MISSING+=("ELASTIC_PASSWORD")
[[ "${KIBANA_PASSWORD:-}"        == "$DEFAULT" || -z "${KIBANA_PASSWORD:-}"        ]] && MISSING+=("KIBANA_PASSWORD")
[[ "${FILEBEAT_USER_PASSWORD:-}" == "$DEFAULT" || -z "${FILEBEAT_USER_PASSWORD:-}" ]] && MISSING+=("FILEBEAT_USER_PASSWORD")

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo ""
  echo "  The following passwords in .env are missing or still set to the default value:"
  for var in "${MISSING[@]}"; do
    echo "    - $var"
  done
  echo ""
  echo "  Generate strong passwords with:"
  echo "    openssl rand -base64 24"
  echo ""
  echo "  Run it once per password and paste each into .env."
  die "Fix .env and re-run the script."
fi

# Alias for clarity in the rest of the script
KIBANA_SYSTEM_PASSWORD="$KIBANA_PASSWORD"

success ".env loaded and all passwords look good."

# =============================================================================
# STEP 1 - Install Docker (official repo)
# =============================================================================

info "Installing Docker..."

if command -v docker &>/dev/null; then
  success "Docker already installed: $(docker --version)"
else
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg

  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -y
  sudo apt-get install -y \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

  sudo systemctl enable docker
  sudo systemctl start docker

  success "Docker installed."
fi

# Add current user to docker group (takes effect on next login)
if ! groups "$USER" | grep -q docker; then
  info "Adding $USER to docker group..."
  sudo usermod -aG docker "$USER"
  warn "You may need to log out and back in (or run 'newgrp docker') for group changes to take effect."
fi

# =============================================================================
# STEP 2 - Kernel tuning for Elasticsearch
# =============================================================================

info "Configuring vm.max_map_count..."

sudo sysctl -w vm.max_map_count=262144

if ! grep -q "vm.max_map_count" /etc/sysctl.conf; then
  echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
  success "vm.max_map_count persisted to /etc/sysctl.conf"
else
  success "vm.max_map_count already in /etc/sysctl.conf"
fi

# =============================================================================
# STEP 3 - Create project directory and copy config files
# =============================================================================

info "Creating $LAB_DIR..."
mkdir -p "$LAB_DIR/data"

info "Copying .env to $LAB_DIR..."
cp "$SCRIPT_DIR/.env" "$LAB_DIR/.env"
success ".env copied."

info "Copying docker-compose.yml to $LAB_DIR..."
cp "$SCRIPT_DIR/docker-compose.yml" "$LAB_DIR/docker-compose.yml"
success "docker-compose.yml copied."

cd "$LAB_DIR"

# =============================================================================
# STEP 4 - Start Elasticsearch (without Kibana first)
# =============================================================================

info "Starting Elasticsearch..."
sudo docker compose up -d elasticsearch

info "Waiting for Elasticsearch to become healthy (up to 60s)..."
for i in $(seq 1 12); do
  if curl -s -u "elastic:${ELASTIC_PASSWORD}" http://localhost:9200 | grep -q "cluster_name"; then
    success "Elasticsearch is up."
    break
  fi
  [[ $i -eq 12 ]] && die "Elasticsearch did not start in time. Check: docker logs elasticsearch"
  echo "  ... waiting (${i}/12)"
  sleep 5
done

# =============================================================================
# STEP 5 - Set kibana_system password via Security API
# =============================================================================

info "Setting kibana_system password..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  -u "elastic:${ELASTIC_PASSWORD}" \
  -X POST "http://localhost:9200/_security/user/kibana_system/_password" \
  -H "Content-Type: application/json" \
  -d "{\"password\": \"${KIBANA_SYSTEM_PASSWORD}\"}")

[[ "$RESPONSE" == "200" ]] \
  && success "kibana_system password set (HTTP 200)." \
  || die "Failed to set kibana_system password (HTTP $RESPONSE). Check: docker logs elasticsearch"

# =============================================================================
# STEP 6 - Start Kibana
# =============================================================================

info "Starting Kibana..."
sudo docker compose up -d kibana
success "Kibana starting — UI will be available at http://localhost:5601 shortly."

# =============================================================================
# STEP 7 - Create filebeat_writer role
# =============================================================================

info "Creating filebeat_writer role..."
curl -s -u "elastic:${ELASTIC_PASSWORD}" \
  -X PUT "http://localhost:9200/_security/role/filebeat_writer" \
  -H "Content-Type: application/json" \
  -d '{
    "cluster": ["monitor", "manage_index_templates", "manage_ilm"],
    "indices": [
      {
        "names": ["filebeat-*"],
        "privileges": ["create_index", "create_doc", "write"]
      }
    ]
  }' > /dev/null
success "filebeat_writer role created."

# =============================================================================
# STEP 8 - Create filebeat_user
# =============================================================================

info "Creating filebeat_user..."
curl -s -u "elastic:${ELASTIC_PASSWORD}" \
  -X POST "http://localhost:9200/_security/user/filebeat_user" \
  -H "Content-Type: application/json" \
  -d "{
    \"password\": \"${FILEBEAT_USER_PASSWORD}\",
    \"roles\": [\"filebeat_writer\"],
    \"full_name\": \"Filebeat Sender\"
  }" > /dev/null
success "filebeat_user created."

# =============================================================================
# DONE
# =============================================================================

echo ""
echo "=============================================="
echo "  Setup complete!"
echo "=============================================="
echo "  Elasticsearch : http://localhost:9200"
echo "  Kibana        : http://localhost:5601"
echo "----------------------------------------------"
echo "  elastic        password : ${ELASTIC_PASSWORD}"
echo "  kibana_system  password : ${KIBANA_SYSTEM_PASSWORD}"
echo "  filebeat_user  password : ${FILEBEAT_USER_PASSWORD}"
echo "=============================================="
