#!/bin/bash

cp ./elastic.yml /etc/elasticsearch/elasticsearch.yml
echo "copied config"

sudo systemctl daemon-reload
# sudo systemctl enable elasticsearch.service
sudo systemctl restart elasticsearch.service

curl http://localhost:9200