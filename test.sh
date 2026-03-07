#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)."
  exit 1
fi

cp ./osquery.conf /etc/osquery/osquery.conf
cp ./osquery.flags /etc/osquery/osquery.flags

echo "osquery configuration files copied successfully."

osqueryi --flagfile /etc/osquery/osquery.flags --extension /etc/osquery/macadmins_extension.amd64.ext
