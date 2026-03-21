#!/bin/bash

cp ./kibana.yml /etc/kibana/kibana.yml
echo "copied config"

sudo systemctl restart kibana

echo "open http://localhost:5601 for UI"