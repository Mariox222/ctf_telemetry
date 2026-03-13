#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)."
  exit 1
fi

cp ./osquery.conf /etc/osquery/osquery.conf
cp ./osquery.flags /etc/osquery/osquery.flags

echo "osquery configuration files copied successfully."

sudo systemctl stop osqueryd
sudo rm -rf /var/log/osquery/*

echo "removed logs"

sudo systemctl restart osqueryd

echo "daemon started"