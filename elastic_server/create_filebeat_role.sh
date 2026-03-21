#!/bin/bash

curl -u elastic:$ELASTIC_PASSWORD -X POST "http://localhost:9200/_security/role/filebeat_writer" -H "Content-Type: application/json" -d '
{
  "cluster": ["monitor", "manage_index_templates", "manage_ilm"],
  "indices": [
    {
      "names": [ "filebeat-*" ],
      "privileges": ["create_index", "create_doc", "write"]
    }
  ]
}'