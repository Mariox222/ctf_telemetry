# Kali Host Setup

Sets up osquery + filebeat on a fresh Kali Linux VM to send telemetry to the Elasticsearch server.

> The full instalation can be left to the participants, or the organizer can pre-configure the VM (steps 1-6) and export it as an `.ova` (for virtualbox) and have the participants import the VM and run the start.sh (step 7.) once imported.

---

## 1. Clone the kali-setup folder and cd into it

```bash
git clone --no-checkout --depth=1 https://github.com/Mariox222/ctf_telemetry.git
cd ctf_telemetry
git sparse-checkout init --cone
git sparse-checkout set kali-setup
git checkout
cd kali-setup
```

---

## 2. Edit filebeat-template.yml

Open `filebeat-template.yml` and fill in two values before running the script:

**Server IP address:**

```yaml
hosts: ["http://<YOUR_SERVER_IP>:9200"]
```

**filebeat_user password** — paste the value from your server's `.env`:

```yaml
password: "<FILEBEAT_USER_PASSWORD>"
```

Save the file.

---

## 3. Install

Make the script executable and run it as root:

> **Warning:** The script clears `~/.bash_history` before starting osqueryd so that pre-installation commands are not tracked. Back up your history first if you need it:
> ```bash
> cp ~/.bash_history ~/.bash_history.bak
> ```

```bash
chmod +x install.sh
sudo ./install.sh
```

The script will update the system, install osquery and filebeat, copy all config files, and start both daemons.

---

## 4. Verify

After the script finishes, check that filebeat can reach the server:

```bash
sudo filebeat test output
```

Expected result: `talk to server... OK`

---

## 5. [Optional] Export .ova

Once verified, export the VM as an `.ova` file from VirtualBox and distribute it to participants.

---

## 6. Run the start script

Run:

```bash
chmod +x start.sh
sudo ./start.sh
```

The script will prompt for a nickname, write it along with the machine ID into the filebeat config, and start osquery and filebeat.
