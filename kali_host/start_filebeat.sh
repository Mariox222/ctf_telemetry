#!/bin/bash

# Load .env
export $(grep -v '^#' .env | xargs)

# Substitute variables into config
envsubst < ./filebeat.yml > /tmp/filebeat.yml

echo "config prepared"

# Copy config
sudo cp /tmp/filebeat.yml /etc/filebeat/filebeat.yml
echo "copied config"

# Restart service
sudo systemctl restart filebeat
echo "filebeat started"

# sudo filebeat test config

# sudo filebeat test output

# sudo systemctl enable filebeat
# sudo systemctl start filebeat

# curl -u elastic:YOUR_PASSWORD "http://localhost:9200/filebeat-*/_search?pretty"