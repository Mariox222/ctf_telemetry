#!/bin/bash
# =============================================================================
# Elasticsearch + Kibana Test Script
# 1. export the password enviroment variables to your enviroment with
#   export $(grep -v '^#' ".env" | xargs)
# 2. export your public IP variable if you want to test externall access with
#   PUBLIC_IP="<YOUR_PUBLIC_IP>"
# 3. copy and paste the test commands you want into the terminal
# =============================================================================

# =============================================================================
# 1. CONTAINER STATUS
# =============================================================================

# Check which containers are running and their current status.
# Expected: elasticsearch and kibana both show as "Up" with no restarts.
# docker ps

# =============================================================================
# 2. FIREWALL
# =============================================================================

# NOTE: UFW is bypassed by Docker. Docker modifies iptables directly, so UFW
# rules do NOT restrict Docker port bindings. Use your cloud provider's
# firewall/security group to control external access to port 9200.

# Show UFW status (informational only — does not reflect actual Docker exposure).
# sudo ufw status verbose

# Check what ports Docker is actually exposing on the host.
# Expected: you should see 0.0.0.0:9200 and 0.0.0.0:5601 listed.
# If Elasticsearch is bound to 127.0.0.1:9200 in docker-compose.yml it will show that instead.
# sudo docker ps --format "table {{.Names}}\t{{.Ports}}"

# External connectivity test — checks if port 9200 is reachable from the internet.
# Expected: should FAIL / time out if your cloud firewall is blocking external access.
# If it returns HTTP 401, port 9200 is publicly exposed (may be intentional for Filebeat).
# curl http://${PUBLIC_IP}:9200

# =============================================================================
# 3. ELASTICSEARCH CONNECTIVITY
# =============================================================================

# Unauthenticated request to Elasticsearch.
# Expected: HTTP 401 Unauthorized — confirms security is enabled.
# You should NOT get cluster info JSON back without credentials.
# curl http://localhost:9200

# Authenticated request to Elasticsearch using the elastic superuser.
# Expected: cluster info JSON with cluster_name, version, etc.
# curl -u elastic:$ELASTIC_PASSWORD http://localhost:9200

# =============================================================================
# 4. INTERNAL NETWORK (KIBANA -> ELASTICSEARCH)
# =============================================================================

# Runs curl from inside the Kibana container against Elasticsearch
# using the internal Docker network hostname.
# Expected: cluster info JSON — confirms Kibana can reach Elasticsearch internally.
# If this fails, Kibana will not be able to connect regardless of what the UI shows.
# docker exec -it kibana curl -u elastic:$ELASTIC_PASSWORD http://elasticsearch:9200

# =============================================================================
# 5. SECURITY OBJECTS
# =============================================================================

# Check whether the filebeat_user was created successfully.
# Expected: JSON response containing:
#   "username": "filebeat_user"
#   "roles": ["filebeat_writer"]
#   "enabled": true
# curl -u elastic:$ELASTIC_PASSWORD "http://localhost:9200/_security/user/filebeat_user?pretty"

# =============================================================================
# 6. INDICES AND DATA INGESTION
# =============================================================================

# List all indices in Elasticsearch.
# Expected: after Filebeat starts shipping logs you will see one or more indices
# whose names start with "filebeat-". If no logs have been received yet,
# no filebeat indices will appear — that is normal at first.
# curl -u elastic:$ELASTIC_PASSWORD "http://localhost:9200/_cat/indices?v"

# Search all documents in filebeat indices.
# Expected: if logs have been received, returns the log documents as JSON.
# If no logs have arrived yet, returns a hits.total of 0 — not an error.
# curl -u elastic:$ELASTIC_PASSWORD "http://localhost:9200/filebeat-*/_search?pretty"

# =============================================================================
# 7. DOCKER LOGS
# =============================================================================

# Stream live Kibana logs — useful for watching startup and auth errors in real time.
# Press Ctrl+C to stop.
# docker logs -f kibana

# Stream live Elasticsearch logs.
# Press Ctrl+C to stop.
# docker logs -f elasticsearch