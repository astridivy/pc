#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Run as root."
  exit 1
fi

BASE_DIR="/opt/geyser"
EXT_DIR="$BASE_DIR/extensions/geyserconnect"
SERVICE_FILE="/etc/systemd/system/geyserconnect.service"
USER_NAME="geyser"

# --- create service user (safe if already exists)
id "$USER_NAME" &>/dev/null || useradd -r -m -U -s /usr/bin/nologin "$USER_NAME"

# --- directories
mkdir -p "$EXT_DIR"
mkdir -p "$BASE_DIR"

cd "$BASE_DIR"

# --- download artifacts
echo "Paste Geyser jar URL:"
read -r GEYSER_URL

wget "$GEYSER_URL" -O Geyser.jar

echo "Paste GeyserConnect jar URL:"
read -r GEC_URL

wget "$GEC_URL" -O "$EXT_DIR/GeyserConnect.jar"

# --- ownership fix (critical bit you were about to miss)
chown -R "$USER_NAME":"$USER_NAME" "$BASE_DIR"

# --- systemd unit
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Geyser Standalone
After=network.target

[Service]
WorkingDirectory=/opt/geyser
ExecStart=/usr/bin/java -jar /opt/geyser/Geyser.jar
Restart=always
RestartSec=5
User=geyser

[Install]
WantedBy=multi-user.target
EOF

# --- activate service
systemctl daemon-reload
systemctl enable geyserconnect
systemctl restart geyserconnect
