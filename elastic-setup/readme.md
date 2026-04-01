# Elastic Stack — Single Node Setup

A scripted setup for a single-node Elasticsearch + Kibana stack running in Docker, with a `filebeat_writer` role and `filebeat_user` for log ingestion.

---

## 1. Description

This repo sets up the following on a fresh linux system:

- Elasticsearch 8.12.0 (single node, security enabled)
- Kibana 8.12.0
- A `filebeat_writer` role and `filebeat_user` for Filebeat log ingestion

The setup script reads your passwords and compose config from the local directory, so there are no hardcoded credentials in the script itself.

---

## 2. Prerequisites — Install Docker

Docker must be installed before running the setup script. If it's not present, the script will exit with an error.

Install Docker on Ubuntu:

```bash
chmod +x install-docker.sh
./install-docker.sh
```

---

## 3. Generate Passwords and Edit `.env`

Before running the installer, you need to fill in the three passwords in `.env`.

**Option A — Automatic (recommended)**

```bash
chmod +x generate-passwords.sh
./generate-passwords.sh
```

This generates strong random passwords and writes them directly into `.env`.

**Option B — Manual**

Generate a strong password by running this command — do it once per password:

```bash
openssl rand -base64 24
```

Then open `.env` and paste each generated password into the appropriate variable:

```env
ELASTIC_PASSWORD=<paste here>
KIBANA_PASSWORD=<paste here>
FILEBEAT_USER_PASSWORD=<paste here>
```

The install script will refuse to run if any password is missing or still set to the default placeholder value.

---

## 4. Install

Make the script executable and run it:

```bash
chmod +x setup-elastic.sh
./setup-elastic.sh
```

The script will install Docker, configure the kernel, copy your config files, start the stack, set all passwords, and create the Filebeat user and role. Docker containers will run on startup.

---

## 5. Firewall

### The UFW problem

UFW is **not effective** for restricting Docker ports. Docker modifies iptables directly and bypasses UFW rules. Even if UFW shows port 9200 as blocked, Elasticsearch will still be publicly reachable.

To actually restrict external access you have two options:

**Option A — Cloud provider firewall (recommended)**

Use your cloud provider's firewall/security group rules to control which IPs can reach port 9200. By default most providers only allow SSH (port 22). To allow Filebeat from a Kali host to ship logs, open port 9200 inbound from the Kali host's IP only.

**Option B — Bind Elasticsearch to localhost**

In `docker-compose.yml`, change the Elasticsearch port binding from `9200:9200` to `127.0.0.1:9200:9200`. This makes Elasticsearch unreachable from outside the VM entirely. Use this if you don't need external access to port 9200.

### Port reference

| Port | Service | Who needs access |
|------|---------|-----------------|
| 22 | SSH | your machine |
| 9200 | Elasticsearch | Kali host running Filebeat |
| 5601 | Kibana | your browser |

---

## 6. Testing

Before running any test, export your passwords into the current shell session:

```bash
export $(grep -v '^#' ".env" | xargs)
```

### Container status

Check which containers are running and their current status.
Expected: elasticsearch and kibana both show as "Up" with no restarts.

```bash
docker ps
```

### Firewall — exposed ports

Check what ports Docker is actually exposing on the host.
Expected: `0.0.0.0:9200` and `0.0.0.0:5601` listed (or `127.0.0.1:9200` if bound to localhost).

```bash
sudo docker ps --format "table {{.Names}}\t{{.Ports}}"
```

UFW status (informational only — does not reflect actual Docker exposure):

```bash
sudo ufw status verbose
```

### Elasticsearch — unauthenticated

Expected: HTTP 401 Unauthorized — confirms security is enabled. You should NOT get cluster info JSON back without credentials.

```bash
curl http://localhost:9200
```

### Elasticsearch — authenticated

Expected: cluster info JSON with `cluster_name`, `version`, etc.

```bash
curl -u elastic:$ELASTIC_PASSWORD http://localhost:9200
```

### Internal network (Kibana → Elasticsearch)

Runs curl from inside the Kibana container against Elasticsearch using the internal Docker network hostname.
Expected: cluster info JSON — confirms Kibana can reach Elasticsearch internally.

```bash
docker exec -it kibana curl -u elastic:$ELASTIC_PASSWORD http://elasticsearch:9200
```

### Security objects

Check whether `filebeat_user` was created successfully.
Expected: JSON with `"username": "filebeat_user"`, `"roles": ["filebeat_writer"]`, `"enabled": true`.

```bash
curl -u elastic:$ELASTIC_PASSWORD "http://localhost:9200/_security/user/filebeat_user?pretty"
```

### Indices

List all indices. After Filebeat starts shipping logs you will see indices whose names start with `filebeat-`. If no logs have been received yet, no filebeat indices will appear — that is normal.

```bash
curl -u elastic:$ELASTIC_PASSWORD "http://localhost:9200/_cat/indices?v"
```

Search all documents in filebeat indices. Returns log documents or `hits.total: 0` if no logs have arrived yet.

```bash
curl -u elastic:$ELASTIC_PASSWORD "http://localhost:9200/filebeat-*/_search?pretty"
```

### Docker logs

Stream live Kibana logs — useful for watching startup and auth errors. Press Ctrl+C to stop.

```bash
docker logs -f kibana
```

Stream live Elasticsearch logs:

```bash
docker logs -f elasticsearch
```

---

## 7. Troubleshooting

### "Kibana server is not ready yet"

**Symptom:** The Kibana web UI at `http://localhost:5601` shows _"Kibana server is not ready yet"_ and never loads.

**Cause:** Kibana cannot authenticate against Elasticsearch. This usually means the `kibana_system` password in your `.env` does not match what Elasticsearch has stored.

**Solution:** Reset the `kibana_system` password and rebuild the Kibana container.

---

**1. Reset the `kibana_system` password**

Elasticsearch will auto-generate a new password and print it to the terminal:

```bash
docker exec -it elasticsearch bin/elasticsearch-reset-password -u kibana_system
```

Copy the printed password.

---

**2. Update `.env` with the new password**

```bash
nano ~/elastic-lab/.env
```

Replace the value of `KIBANA_PASSWORD` with the password printed in step 1.

---

**3. Reload environment variables in your shell**

```bash
cd ~/elastic-lab
export $(grep -v '^#' .env | xargs)
```

---

**4. Rebuild the Kibana container**

```bash
docker compose down
docker compose up -d --force-recreate kibana
```

---

**Verification**

Check that the password was injected into the container — the printed value must match `KIBANA_PASSWORD` in your `.env`:

```bash
docker exec -it kibana env | grep ELASTICSEARCH_PASSWORD
```

Then confirm Kibana can reach and authenticate against Elasticsearch — expected result is cluster info JSON:

```bash
docker exec -it kibana curl -u elastic:$ELASTIC_PASSWORD http://elasticsearch:9200
```

If both checks pass, reload the Kibana UI in your browser. It should come up within 30–60 seconds.