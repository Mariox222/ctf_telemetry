# Kali Host Setup

Sets up osquery + filebeat on a fresh Kali Linux VM to send telemetry to the Elasticsearch server.

> The full instalation can be left to the participants, or the organizer can pre-configure the VM (steps 1-6) and export it as an `.ova` (for virtualbox) and have the participants import the VM and run the start.sh (step 7.) once imported.

---

## 1. Go to the kali-setup folder

```bash
cd kali-setup
```

---

## 2. Required Files

Make sure all of the following are in the same directory:

- `install.sh`
- `osquery_5.21.0-1.linux_amd64.deb`
- `macadmins_extension.amd64.ext`
- `osquery.conf`
- `osquery.flags`
- `filebeat-template.yml`
- `start.sh`

---

## 3. Edit filebeat-template.yml

Open `filebeat-template.yml` and fill in two values before running the script:

**Server IP address:**

```yaml
hosts: ["http://<YOUR_SERVER_IP>:9200"]
```

**filebeat_user password** — paste the value from your server's `.env`:

```yaml
password: "<FILEBEAT_USER_PASSWORD>"
```

Save the file. The script copies it as-is to `/etc/filebeat/filebeat.yml`.

---

## 4. Install

Make the script executable and run it as root:

```bash
chmod +x install.sh
sudo ./install.sh
```

The script will update the system, install osquery and filebeat, copy all config files, and start both daemons.

---

## 5. Verify

After the script finishes, check that filebeat can reach the server:

```bash
sudo filebeat test output
```

Expected result: `talk to server... OK`

---

## 6. [Optional] Export .ova

Once verified, export the VM as an `.ova` file from VirtualBox and distribute it to participants.

---

## 7. Run the start script

Run:

```bash
chmod +x start.sh
sudo ./start.sh
```

The script will prompt for a nickname, write it along with the machine ID into the filebeat config, and start osquery and filebeat.
