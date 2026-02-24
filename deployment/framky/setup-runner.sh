#!/usr/bin/env bash
# Setup GitHub Actions self-hosted runner for Chatwoot
# Run as root on server-framky
set -euo pipefail

RUNNER_USER="gh-runner"
RUNNER_DIR="/srv/gh-runner-chatwoot"
RUNNER_NAME="chatwoot-runner"
REPO="lukaszolek/chatwoot"
SERVICE_NAME="gh-runner-chatwoot"

echo "=== Setting up GitHub Actions Runner for Chatwoot ==="

# ─── 1. Ensure runner user exists ───
if ! id "${RUNNER_USER}" &>/dev/null; then
  echo "Creating user ${RUNNER_USER}..."
  useradd -m -s /bin/bash "${RUNNER_USER}"
fi

# ─── 2. Create runner directory ───
mkdir -p "${RUNNER_DIR}"
chown "${RUNNER_USER}:${RUNNER_USER}" "${RUNNER_DIR}"

# ─── 3. Download runner ───
echo "Downloading latest GitHub Actions runner..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | grep -oP '"tag_name": "v\K[^"]+')
RUNNER_ARCHIVE="actions-runner-linux-x64-${LATEST_VERSION}.tar.gz"

sudo -u "${RUNNER_USER}" bash -c "
  cd ${RUNNER_DIR}
  if [ ! -f run.sh ]; then
    curl -sL https://github.com/actions/runner/releases/download/v${LATEST_VERSION}/${RUNNER_ARCHIVE} -o runner.tar.gz
    tar xzf runner.tar.gz
    rm runner.tar.gz
  fi
"

# ─── 4. Register runner ───
echo ""
echo "!! Get a registration token from:"
echo "   https://github.com/${REPO}/settings/actions/runners/new"
echo ""
read -rp "Enter registration token: " REG_TOKEN

sudo -u "${RUNNER_USER}" bash -c "
  cd ${RUNNER_DIR}
  ./config.sh \
    --url https://github.com/${REPO} \
    --token ${REG_TOKEN} \
    --name ${RUNNER_NAME} \
    --labels self-hosted,linux,x64,chatwoot \
    --work _work \
    --unattended
"

# ─── 5. Install systemd service ───
echo "Installing systemd service..."
cat > "/etc/systemd/system/${SERVICE_NAME}.service" << EOF
[Unit]
Description=GitHub Actions Runner (Chatwoot)
After=network.target

[Service]
Type=simple
User=${RUNNER_USER}
WorkingDirectory=${RUNNER_DIR}
ExecStart=${RUNNER_DIR}/run.sh
Restart=always
RestartSec=5
KillMode=process
KillSignal=SIGTERM
TimeoutStopSec=30
MemoryMax=8G

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"
systemctl start "${SERVICE_NAME}"

echo ""
echo "=== Runner setup complete! ==="
echo "Check status: systemctl status ${SERVICE_NAME}"
echo "View logs: journalctl -u ${SERVICE_NAME} -f"
