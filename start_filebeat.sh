#!/bin/bash

cp ./filebeat.yml /etc/filebeat/filebeat.yml
echo "copied config"

sudo systemctl restart filebeat

# sudo journalctl -u filebeat -f