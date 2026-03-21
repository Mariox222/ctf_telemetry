#!/bin/bash

# export $(grep -v '^#' .env | xargs)

curl -u elastic:$ELASTIC_PASSWORD -X POST "http://localhost:9200/_security/user/filebeat_user" -H "Content-Type: application/json" -d '
{
  "password": "$FILE_BEAT_USER_PASSWORD",
  "roles": ["filebeat_writer"],
  "full_name": "Filebeat Sender"
}'