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

**5. Make the script executable and run it**

```bash
chmod +x install.sh
./install.sh
```

> See `elastic-setup/readme.md` for full documentation.
