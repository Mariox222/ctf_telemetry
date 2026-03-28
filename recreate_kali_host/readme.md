# Kali Host Setup

Sets up osquery + filebeat on a fresh Kali Linux VM to send telemetry to the Elasticsearch server.

---

## 1. Required Files

Before running the install script, make sure all of the following are in the same directory:

- `setup-kali.sh`
- `osquery_5.21.0-1.linux_amd64.deb`
- `macadmins_extension.amd64.ext`
- `osquery.conf`
- `osquery.flags`
- `filebeat.yml`

---

## 2. Download osquery

Download the osquery `.deb` package from the official osquery release page:

```
https://github.com/osquery/osquery/releases/tag/5.21.0
```

Look for `osquery_5.21.0-1.linux_amd64.deb` under the Assets section and download it into the same directory as the script.

---

## 3. Edit filebeat.yml

Open `filebeat.yml` and fill in two values before running the script:

**Server IP address** — find the line with the Elasticsearch output host and replace the placeholder with your server's public IP:

```yaml
hosts: ["<YOUR_SERVER_IP>:9200"]
```

**filebeat_user password** — find the password field under the Elasticsearch output and paste in the password from your server's `.env`:

```yaml
password: "<FILEBEAT_USER_PASSWORD>"
```

Save the file. The script copies it as-is to `/etc/filebeat/filebeat.yml` so it must be correct before you run anything.

---

## 4. Install

Make the script executable and run it as root:

```bash
chmod +x setup-kali.sh
sudo ./setup-kali.sh
```

The script will update the system, install osquery and filebeat, copy all config files, and start both daemons.

---

## 5. Verify

After the script finishes, check that filebeat can reach the server:

```bash
sudo filebeat test output
```

Expected result: `talk to server... OK` — if you get a connection error, double-check the server IP and password in `filebeat.yml`.

Watch live filebeat logs to confirm data is being shipped:

```bash
sudo journalctl -u filebeat -f
```

---

## 6. Optional Manual Steps

These are not handled by the script and need to be done manually:

**Croatian keyboard layout**
Settings → Keyboard → Add Input Source → Croatian

**VS Code**
Download the `.deb` from `https://code.visualstudio.com`, then:

```bash
sudo apt install ./code_*.deb
```