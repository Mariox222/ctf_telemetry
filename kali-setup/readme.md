# Kali Host Setup

Sets up osquery + filebeat on a fresh Kali Linux VM to send telemetry to the Elasticsearch server.

There are two roles: the **organizer** sets up and exports the VM, the **participant** imports it and runs the start script.

---

## Organizer Workflow

### 1. Required Files

Before running the install script, make sure all of the following are in the same directory:

- `install.sh`
- `osquery_5.21.0-1.linux_amd64.deb`
- `macadmins_extension.amd64.ext`
- `osquery.conf`
- `osquery.flags`
- `filebeat-template.yml`
- `start.sh`

---

### 2. Download osquery

Download the osquery `.deb` package from the official osquery release page:

```
https://github.com/osquery/osquery/releases/tag/5.21.0
```

Look for `osquery_5.21.0-1.linux_amd64.deb` under Assets and download it into the same directory as the script.

---

### 3. Edit filebeat-template.yml

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

### 4. Install

Make the script executable and run it as root:

```bash
chmod +x install.sh
sudo ./install.sh
```

The script will update the system, install osquery and filebeat, copy all config files, and start both daemons.

---

### 5. Verify

After the script finishes, check that filebeat can reach the server:

```bash
sudo filebeat test output
```

Expected result: `talk to server... OK`

---

### 6. Export .ova

Once verified, export the VM as an `.ova` file from VirtualBox and distribute it to participants.

---

## Participant Workflow

### 1. Import the .ova

Import the `.ova` file in VirtualBox and start the VM.

### 2. Run the start script

```bash
chmod +x start.sh
sudo ./start.sh
```

The script will prompt you for a nickname, write it along with the machine ID into the filebeat config, and start osquery and filebeat.

---

## Optional Manual Steps

**Croatian keyboard layout**
Settings → Keyboard → Add Input Source → Croatian

**VS Code**
Download the `.deb` from `https://code.visualstudio.com`, then:

```bash
sudo apt install ./code_*.deb
```
