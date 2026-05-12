#!/bin/bash
set -euo pipefail

sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker --now
sudo usermod -aG docker $USER
newgrp docker
