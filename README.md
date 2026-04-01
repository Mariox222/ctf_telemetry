# ctf_telemetry

## Quick Start — Elastic Server Setup

**1. Clone the repo**

SSH (requires GitHub SSH key on the server):
```bash
git clone git@github.com:Mariox222/ctf_telemetry.git
cd ctf_telemetry
```

HTTPS (no SSH key needed):
```bash
git clone https://github.com/Mariox222/ctf_telemetry.git
cd ctf_telemetry
```

**2. Go to the elastic server setup folder**

```bash
cd elastic-setup
```

**3. Install docker with docker compose if not present**

Check if docker compose is present:

```bash
docker compose version
```

For installing on Ubuntu, you can use the provided script:

```bash
chmod +x install-docker.sh
./install-docker.sh
```

**4. Fill in passwords in `.env`**

Generate a strong password for each variable (run once per password for
a total of 3 different passwords):

```bash
openssl rand -base64 24
```

Open `.env` and paste each generated value:

```env
ELASTIC_PASSWORD=<paste here>
KIBANA_PASSWORD=<paste here>
FILEBEAT_USER_PASSWORD=<paste here>
```

**5. Make the script executable and run it**

```bash
chmod +x install.sh
./install.sh
```

> See `elastic-setup/readme.md` for full documentation.
