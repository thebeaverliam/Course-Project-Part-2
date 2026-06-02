#!/usr/bin/env bash
set -euo pipefail

dnf update -y
dnf install -y java-21-amazon-corretto-headless python3

useradd --system --home-dir /opt/minecraft --shell /sbin/nologin minecraft || true

mkdir -p /opt/minecraft/server
cd /opt/minecraft/server

python3 <<'PY'
import json
import urllib.request

MC_VERSION = "1.21.1"
manifest_url = "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"

with urllib.request.urlopen(manifest_url) as r:
    manifest = json.load(r)

version = next(v for v in manifest["versions"] if v["id"] == MC_VERSION)

with urllib.request.urlopen(version["url"]) as r:
    data = json.load(r)

server_url = data["downloads"]["server"]["url"]
urllib.request.urlretrieve(server_url, "server.jar")

print("Downloaded Minecraft version:", MC_VERSION)
PY

cat > eula.txt <<'EOF'
eula=true
EOF

cat > server.properties <<'EOF'
motd=Acme Minecraft Server
server-port=25565
online-mode=true
max-players=20
difficulty=easy
EOF

chown -R minecraft:minecraft /opt/minecraft

cat > /etc/systemd/system/minecraft.service <<'EOF'
[Unit]
Description=Minecraft Server
After=network-online.target

[Service]
User=minecraft
WorkingDirectory=/opt/minecraft/server
ExecStart=/usr/bin/java -Xms512M -Xmx1G -jar server.jar nogui
Restart=on-failure
KillSignal=SIGINT
TimeoutStopSec=120

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable minecraft
systemctl restart minecraft

sleep 15

systemctl --no-pager status minecraft || true
ss -lntp | grep 25565 || true
