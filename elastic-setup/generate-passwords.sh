#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

info()    { echo -e "\n\033[1;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[1;32m[OK]\033[0m $*"; }
die()     { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; exit 1; }

[[ -f "$ENV_FILE" ]] || die ".env not found in $SCRIPT_DIR."

info "Generating passwords..."

ELASTIC_PASSWORD=$(openssl rand -base64 24)
KIBANA_PASSWORD=$(openssl rand -base64 24)
FILEBEAT_USER_PASSWORD=$(openssl rand -base64 24)

sed -i \
  -e "s|ELASTIC_PASSWORD=.*|ELASTIC_PASSWORD=${ELASTIC_PASSWORD}|" \
  -e "s|KIBANA_PASSWORD=.*|KIBANA_PASSWORD=${KIBANA_PASSWORD}|" \
  -e "s|FILEBEAT_USER_PASSWORD=.*|FILEBEAT_USER_PASSWORD=${FILEBEAT_USER_PASSWORD}|" \
  "$ENV_FILE"

success "Passwords generated and written to .env."