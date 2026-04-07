# CTF Telemetry — Installation Guide

This repo is cloned in two places:
- **On the server** where Elasticsearch + Kibana will run
- **On the Kali VM** where telemetry collection will be set up

---

## Clone the repo

SSH (requires GitHub SSH key):
```bash
git clone git@github.com:Mariox222/ctf_telemetry.git
cd ctf_telemetry
```

HTTPS (no SSH key needed):
```bash
git clone https://github.com/Mariox222/ctf_telemetry.git
cd ctf_telemetry
```

---

## Setup guides

- [Elastic Server Setup](https://github.com/Mariox222/ctf_telemetry/blob/main/elastic-setup/readme.md) — deploy the Elasticsearch + Kibana stack on the server
- [Kali Host Setup](https://github.com/Mariox222/ctf_telemetry/blob/main/kali-setup/readme.md) — set up the Kali VM for telemetry collection
