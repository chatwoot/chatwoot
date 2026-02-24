#!/usr/bin/env bash
# Setup script for Chatwoot on server-framky (Ubuntu 24.04)
# Run once as root via SSH: sudo bash setup-server.sh
set -euo pipefail

CHATWOOT_USER="chatwoot"
CHATWOOT_HOME="/srv/chatwoot"
APP_DIR="${CHATWOOT_HOME}/chatwoot"
RUBY_VERSION="3.4.4"
REPO_URL="git@github.com:lukaszolek/chatwoot.git"
REPO_BRANCH="framky/main"
DOMAIN="crm.framky.com"

echo "=== Chatwoot Server Setup for ${DOMAIN} ==="

# ─── 1. System user ───
if ! id "${CHATWOOT_USER}" &>/dev/null; then
  echo "Creating system user ${CHATWOOT_USER}..."
  useradd -m -d "${CHATWOOT_HOME}" -s /bin/bash "${CHATWOOT_USER}"
else
  echo "User ${CHATWOOT_USER} already exists."
fi

# ─── 2. System dependencies ───
echo "Installing system dependencies..."
apt-get update -qq
apt-get install -y -qq \
  git curl wget build-essential libssl-dev libreadline-dev zlib1g-dev \
  libsqlite3-dev libpq-dev libffi-dev libyaml-dev libxml2-dev libxslt1-dev \
  autoconf bison libtool imagemagick libvips \
  postgresql-client redis-tools

# ─── 3. Ruby via rbenv ───
echo "Setting up rbenv + Ruby ${RUBY_VERSION} for ${CHATWOOT_USER}..."
sudo -u "${CHATWOOT_USER}" bash -c '
  set -euo pipefail
  if [ ! -d "${HOME}/.rbenv" ]; then
    git clone https://github.com/rbenv/rbenv.git "${HOME}/.rbenv"
    git clone https://github.com/rbenv/ruby-build.git "${HOME}/.rbenv/plugins/ruby-build"
  fi

  export PATH="${HOME}/.rbenv/bin:${PATH}"
  eval "$(rbenv init -)"

  # Add to bashrc if not present
  if ! grep -q "rbenv init" "${HOME}/.bashrc" 2>/dev/null; then
    echo "export PATH=\"\${HOME}/.rbenv/bin:\${PATH}\"" >> "${HOME}/.bashrc"
    echo "eval \"\$(rbenv init -)\"" >> "${HOME}/.bashrc"
  fi

  if ! rbenv versions | grep -q "'"${RUBY_VERSION}"'"; then
    rbenv install "'"${RUBY_VERSION}"'"
  fi
  rbenv global "'"${RUBY_VERSION}"'"
  gem install bundler --no-document
'

# ─── 4. Node.js + pnpm ───
echo "Setting up Node.js and pnpm..."
if ! command -v node &>/dev/null; then
  curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
  apt-get install -y -qq nodejs
fi
if ! command -v pnpm &>/dev/null; then
  npm install -g pnpm@10
fi

# ─── 5. PostgreSQL database ───
echo "Setting up PostgreSQL database..."
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='chatwoot'" | grep -q 1; then
  echo "PostgreSQL user 'chatwoot' already exists."
else
  CHATWOOT_DB_PASSWORD=$(openssl rand -hex 24)
  sudo -u postgres psql -c "CREATE USER chatwoot WITH PASSWORD '${CHATWOOT_DB_PASSWORD}';"
  echo ""
  echo "!! SAVE THIS — PostgreSQL password for chatwoot: ${CHATWOOT_DB_PASSWORD}"
  echo ""
fi
sudo -u postgres psql -c "CREATE DATABASE chatwoot_production OWNER chatwoot;" 2>/dev/null || echo "Database already exists."

# ─── 6. Clone repository ───
if [ ! -d "${APP_DIR}" ]; then
  echo "Cloning repository..."
  sudo -u "${CHATWOOT_USER}" git clone -b "${REPO_BRANCH}" "${REPO_URL}" "${APP_DIR}"
else
  echo "Repository already cloned at ${APP_DIR}."
fi

# ─── 7. Environment file ───
if [ ! -f "${APP_DIR}/.env" ]; then
  echo "Creating .env from template..."
  sudo -u "${CHATWOOT_USER}" cp "${APP_DIR}/.env.example" "${APP_DIR}/.env"

  # Generate SECRET_KEY_BASE
  SECRET_KEY_BASE=$(openssl rand -hex 64)
  sudo -u "${CHATWOOT_USER}" sed -i "s/^SECRET_KEY_BASE=.*/SECRET_KEY_BASE=${SECRET_KEY_BASE}/" "${APP_DIR}/.env"

  # Set production defaults
  sudo -u "${CHATWOOT_USER}" sed -i "s|^FRONTEND_URL=.*|FRONTEND_URL=https://${DOMAIN}|" "${APP_DIR}/.env"
  sudo -u "${CHATWOOT_USER}" sed -i "s|^REDIS_URL=.*|REDIS_URL=redis://127.0.0.1:6379/2|" "${APP_DIR}/.env"
  sudo -u "${CHATWOOT_USER}" sed -i "s/^RAILS_ENV=.*/RAILS_ENV=production/" "${APP_DIR}/.env"
  sudo -u "${CHATWOOT_USER}" sed -i "s/^POSTGRES_HOST=.*/POSTGRES_HOST=localhost/" "${APP_DIR}/.env"
  sudo -u "${CHATWOOT_USER}" sed -i "s/^POSTGRES_USERNAME=.*/POSTGRES_USERNAME=chatwoot/" "${APP_DIR}/.env"
  sudo -u "${CHATWOOT_USER}" sed -i "s/^FORCE_SSL=.*/FORCE_SSL=true/" "${APP_DIR}/.env"

  echo ""
  echo "!! Edit ${APP_DIR}/.env to set:"
  echo "   - POSTGRES_PASSWORD (from step 5 above)"
  echo "   - SMTP settings"
  echo "   - ACTIVE_RECORD_ENCRYPTION keys (run: rails db:encryption:init)"
  echo ""
else
  echo ".env file already exists."
fi

# ─── 8. Install dependencies & build ───
echo "Installing Ruby and Node dependencies..."
sudo -u "${CHATWOOT_USER}" bash -lc "
  cd ${APP_DIR}
  bundle install --deployment --without development test
  pnpm install --frozen-lockfile
"

echo "Precompiling assets..."
sudo -u "${CHATWOOT_USER}" bash -lc "
  cd ${APP_DIR}
  RAILS_ENV=production NODE_ENV=production bundle exec rails assets:precompile
"

echo "Preparing database..."
sudo -u "${CHATWOOT_USER}" bash -lc "
  cd ${APP_DIR}
  RAILS_ENV=production bundle exec rails db:chatwoot_prepare
"

# ─── 9. Systemd services ───
echo "Installing systemd services..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cp "${SCRIPT_DIR}/chatwoot-web.service" /etc/systemd/system/chatwoot-web.service
cp "${SCRIPT_DIR}/chatwoot-worker.service" /etc/systemd/system/chatwoot-worker.service
cp "${SCRIPT_DIR}/chatwoot.target" /etc/systemd/system/chatwoot.target

systemctl daemon-reload
systemctl enable chatwoot.target
systemctl start chatwoot.target

echo "Waiting for web server to start..."
sleep 5
systemctl status chatwoot-web.service --no-pager || true

# ─── 10. Sudoers ───
echo "Installing sudoers rules..."
cp "${SCRIPT_DIR}/chatwoot-sudoers" /etc/sudoers.d/chatwoot
chmod 440 /etc/sudoers.d/chatwoot
visudo -c -f /etc/sudoers.d/chatwoot

# ─── 11. Nginx ───
echo "Installing nginx config..."
cp "${SCRIPT_DIR}/nginx-chatwoot.conf" /etc/nginx/sites-available/chatwoot
ln -sf /etc/nginx/sites-available/chatwoot /etc/nginx/sites-enabled/chatwoot
nginx -t && systemctl reload nginx

# ─── 12. SSL via Certbot ───
echo "Setting up SSL certificate..."
if [ ! -d "/etc/letsencrypt/live/${DOMAIN}" ]; then
  certbot --nginx -d "${DOMAIN}" --non-interactive --agree-tos --email admin@framky.com
else
  echo "SSL certificate already exists for ${DOMAIN}."
fi

echo ""
echo "=== Setup complete! ==="
echo "Chatwoot should be running at https://${DOMAIN}"
echo ""
echo "Next steps:"
echo "  1. Edit ${APP_DIR}/.env with your POSTGRES_PASSWORD and other settings"
echo "  2. Restart: sudo systemctl restart chatwoot.target"
echo "  3. Check logs: journalctl -u chatwoot-web -f"
echo "  4. Check worker: journalctl -u chatwoot-worker -f"
