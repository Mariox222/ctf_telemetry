# Elastic Stack — Single Node Setup

A scripted setup for a single-node Elasticsearch + Kibana stack running in Docker, with a `filebeat_writer` role and `filebeat_user` for log ingestion.

---

## 1. Description

This repo sets up the following on a fresh Ubuntu VM:

- Elasticsearch 8.12.0 (single node, security enabled)
- Kibana 8.12.0
- A `filebeat_writer` role and `filebeat_user` for Filebeat log ingestion

The setup script reads your passwords and compose config from the local directory, so there are no hardcoded credentials in the script itself.

---

## 2. Prerequisites — Install Docker

Docker must be installed before running the setup script. If it's not present, the script will exit with an error.

Install Docker on Debian/Ubuntu:

```bash
chmod +x install-docker.sh
./install-docker.sh
```

---

## 3. Generate Passwords and Edit `.env`

Before running the installer, you need to fill in the three passwords in `.env`.

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

The script will refuse to run if any password is missing or still set to the default placeholder value.

---

## 4. Install

Make the script executable and run it:

```bash
chmod +x setup-elastic.sh
./setup-elastic.sh
```

The script will install Docker, configure the kernel, copy your config files, start the stack, set all passwords, and create the Filebeat user and role. Docker containers will run on startup.

---

## 5. Testing

Open `test.sh` and read through the available tests before running anything. Each test is commented out with a description of what it checks and what the expected result is.


---

## 6. Troubleshooting

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