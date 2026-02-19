#!/bin/bash
# ============================================================================
# Installer Autonomo - Build & Deploy desde repositorio propio
# ============================================================================
# Este script instala/actualiza la aplicacion desde el repositorio GtrhSystems
# Sin conexiones externas a Chatwoot - 100% independiente
# Enterprise completo habilitado
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/GtrhSystems/chatwoot.git"
REPO_BRANCH="develop"
INSTALL_DIR="/home/chatwoot/chatwoot"
DATA_DIR="/data"

# ============================================================================
# Helper functions
# ============================================================================
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    log_error "Este script debe ejecutarse como root (sudo)"
    exit 1
  fi
}

# ============================================================================
# Detect OS
# ============================================================================
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_VERSION=$VERSION_ID
  else
    log_error "No se puede detectar el sistema operativo"
    exit 1
  fi
  log_info "Sistema detectado: $OS $OS_VERSION"
}

# ============================================================================
# Install system dependencies
# ============================================================================
install_dependencies() {
  log_step "Instalando dependencias del sistema..."

  apt-get update -qq

  # Essential packages
  apt-get install -y -qq \
    git curl wget gnupg2 apt-transport-https ca-certificates \
    software-properties-common lsb-release \
    build-essential libssl-dev libreadline-dev zlib1g-dev \
    libpq-dev libxml2-dev libxslt1-dev libffi-dev \
    imagemagick libvips-dev \
    nginx certbot python3-certbot-nginx \
    postgresql postgresql-contrib \
    redis-server \
    > /dev/null 2>&1

  log_info "Dependencias del sistema instaladas"
}

# ============================================================================
# Install pgvector extension
# ============================================================================
install_pgvector() {
  log_step "Instalando pgvector para PostgreSQL..."

  PG_VERSION=$(pg_config --version | grep -oP '\d+' | head -1)

  if ! dpkg -l | grep -q "postgresql-${PG_VERSION}-pgvector"; then
    apt-get install -y -qq "postgresql-${PG_VERSION}-pgvector" 2>/dev/null || {
      log_warn "pgvector no disponible en repos, compilando desde fuente..."
      cd /tmp
      git clone --branch v0.7.4 https://github.com/pgvector/pgvector.git 2>/dev/null
      cd pgvector
      make && make install
      cd /tmp && rm -rf pgvector
    }
  fi

  log_info "pgvector instalado"
}

# ============================================================================
# Install Ruby via RVM
# ============================================================================
install_ruby() {
  local RUBY_VERSION="3.3.3"

  if command -v ruby &>/dev/null && ruby -v | grep -q "$RUBY_VERSION"; then
    log_info "Ruby $RUBY_VERSION ya esta instalado"
    return
  fi

  log_step "Instalando Ruby $RUBY_VERSION via RVM..."

  if ! command -v rvm &>/dev/null; then
    curl -sSL https://rvm.io/mpapis.asc | gpg2 --import - 2>/dev/null
    curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import - 2>/dev/null
    curl -sSL https://get.rvm.io | bash -s stable 2>/dev/null
    source /etc/profile.d/rvm.sh 2>/dev/null || source /usr/local/rvm/scripts/rvm 2>/dev/null
  fi

  rvm install "$RUBY_VERSION" --default 2>/dev/null
  rvm use "$RUBY_VERSION" --default 2>/dev/null

  gem install bundler

  log_info "Ruby $RUBY_VERSION instalado"
}

# ============================================================================
# Install Node.js
# ============================================================================
install_node() {
  local NODE_MAJOR="23"

  if command -v node &>/dev/null && node -v | grep -q "v${NODE_MAJOR}"; then
    log_info "Node.js $(node -v) ya esta instalado"
    return
  fi

  log_step "Instalando Node.js ${NODE_MAJOR}.x..."

  curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - 2>/dev/null
  apt-get install -y -qq nodejs 2>/dev/null

  npm install -g pnpm@latest 2>/dev/null

  log_info "Node.js $(node -v) y pnpm instalados"
}

# ============================================================================
# Create chatwoot system user
# ============================================================================
create_user() {
  if id "chatwoot" &>/dev/null; then
    log_info "Usuario chatwoot ya existe"
    return
  fi

  log_step "Creando usuario del sistema chatwoot..."
  useradd -m -s /bin/bash chatwoot
  log_info "Usuario chatwoot creado"
}

# ============================================================================
# Setup PostgreSQL
# ============================================================================
setup_postgres() {
  log_step "Configurando PostgreSQL..."

  systemctl enable postgresql
  systemctl start postgresql

  # Create database user
  sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='chatwoot'" | grep -q 1 || {
    PG_PASSWORD=$(openssl rand -hex 12)
    sudo -u postgres psql -c "CREATE USER chatwoot WITH PASSWORD '$PG_PASSWORD' CREATEDB;" 2>/dev/null
    echo "POSTGRES_PASSWORD=$PG_PASSWORD" >> /tmp/.chatwoot_pg_pass
    log_info "Usuario PostgreSQL creado (password guardado en /tmp/.chatwoot_pg_pass)"
  }

  # Enable pgvector
  sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS vector;" 2>/dev/null || true

  log_info "PostgreSQL configurado"
}

# ============================================================================
# Setup Redis
# ============================================================================
setup_redis() {
  log_step "Configurando Redis..."

  REDIS_PASSWORD=$(openssl rand -hex 12)

  # Configure Redis with password
  if ! grep -q "^requirepass" /etc/redis/redis.conf 2>/dev/null; then
    echo "requirepass $REDIS_PASSWORD" >> /etc/redis/redis.conf
    echo "REDIS_PASSWORD=$REDIS_PASSWORD" >> /tmp/.chatwoot_redis_pass
  else
    REDIS_PASSWORD=$(grep "^requirepass" /etc/redis/redis.conf | awk '{print $2}')
  fi

  systemctl enable redis-server
  systemctl restart redis-server

  log_info "Redis configurado"
}

# ============================================================================
# Clone or update repository
# ============================================================================
setup_repo() {
  log_step "Configurando repositorio..."

  if [ -d "$INSTALL_DIR/.git" ]; then
    log_info "Repositorio existente, actualizando..."
    cd "$INSTALL_DIR"
    sudo -u chatwoot git fetch origin "$REPO_BRANCH"
    sudo -u chatwoot git checkout "$REPO_BRANCH"
    sudo -u chatwoot git pull origin "$REPO_BRANCH"
  else
    log_info "Clonando repositorio desde $REPO_URL..."
    mkdir -p "$(dirname $INSTALL_DIR)"
    chown chatwoot:chatwoot "$(dirname $INSTALL_DIR)"
    sudo -u chatwoot git clone -b "$REPO_BRANCH" "$REPO_URL" "$INSTALL_DIR"
  fi

  cd "$INSTALL_DIR"
  log_info "Repositorio listo en $INSTALL_DIR"
}

# ============================================================================
# Configure environment
# ============================================================================
configure_env() {
  log_step "Configurando variables de entorno..."

  local ENV_FILE="$INSTALL_DIR/.env"
  local DOMAIN="${1:-localhost}"

  # Read saved passwords
  local PG_PASS=""
  local RD_PASS=""
  [ -f /tmp/.chatwoot_pg_pass ] && PG_PASS=$(grep POSTGRES_PASSWORD /tmp/.chatwoot_pg_pass | cut -d= -f2)
  [ -f /tmp/.chatwoot_redis_pass ] && RD_PASS=$(grep REDIS_PASSWORD /tmp/.chatwoot_redis_pass | cut -d= -f2)

  # Use existing passwords if available
  if [ -f "$ENV_FILE" ]; then
    [ -z "$PG_PASS" ] && PG_PASS=$(grep "^POSTGRES_PASSWORD=" "$ENV_FILE" | cut -d= -f2)
    [ -z "$RD_PASS" ] && RD_PASS=$(grep "^REDIS_PASSWORD=" "$ENV_FILE" | cut -d= -f2)
  fi

  local SECRET_KEY=$(cd "$INSTALL_DIR" && sudo -u chatwoot bash -lc "RAILS_ENV=production bundle exec rake secret" 2>/dev/null || openssl rand -hex 64)

  # Keep existing SECRET_KEY_BASE if present
  if [ -f "$ENV_FILE" ]; then
    local EXISTING_SECRET=$(grep "^SECRET_KEY_BASE=" "$ENV_FILE" | cut -d= -f2)
    [ -n "$EXISTING_SECRET" ] && [ "$EXISTING_SECRET" != "replace_with_lengthy_secure_hex" ] && SECRET_KEY="$EXISTING_SECRET"
  fi

  cat > "$ENV_FILE" << ENVEOF
# ============================================
# Generated by installer - $(date +%Y-%m-%d)
# Enterprise Edition - All features enabled
# No external Chatwoot connections
# ============================================

SECRET_KEY_BASE=$SECRET_KEY

# Domain
FRONTEND_URL=https://$DOMAIN
HELPCENTER_URL=https://$DOMAIN

# Rails
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
RAILS_MAX_THREADS=5
LOG_LEVEL=info
FORCE_SSL=true

# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_USERNAME=chatwoot
POSTGRES_PASSWORD=$PG_PASS

# Redis
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=$RD_PASS

# Storage
ACTIVE_STORAGE_SERVICE=local

# Account
ENABLE_ACCOUNT_SIGNUP=false

# SMTP (configure with your provider)
MAILER_SENDER_EMAIL=soporte <noreply@$DOMAIN>
SMTP_DOMAIN=$DOMAIN
SMTP_ADDRESS=
SMTP_PORT=587
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_AUTHENTICATION=login
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_OPENSSL_VERIFY_MODE=peer

# Disable ALL external Chatwoot connections
DISABLE_TELEMETRY=true
ENABLE_PUSH_RELAY_SERVER=false
CW_EDITION=enterprise
INSTALLATION_ENV=self-hosted

# Logging (no Sentry)
# SENTRY_DSN=
ENVEOF

  chown chatwoot:chatwoot "$ENV_FILE"
  chmod 600 "$ENV_FILE"

  # Cleanup temp password files
  rm -f /tmp/.chatwoot_pg_pass /tmp/.chatwoot_redis_pass

  log_info "Archivo .env configurado para $DOMAIN"
}

# ============================================================================
# Install application dependencies
# ============================================================================
install_app() {
  log_step "Instalando dependencias de la aplicacion..."

  cd "$INSTALL_DIR"

  # Ruby dependencies
  sudo -u chatwoot bash -lc "cd $INSTALL_DIR && gem install bundler && bundle config set --local deployment true && bundle config set --local without 'development test' && bundle install -j$(nproc)"

  # Node dependencies
  sudo -u chatwoot bash -lc "cd $INSTALL_DIR && pnpm install"

  log_info "Dependencias instaladas"
}

# ============================================================================
# Setup database
# ============================================================================
setup_database() {
  log_step "Configurando base de datos..."

  cd "$INSTALL_DIR"

  # Check if database exists
  if sudo -u chatwoot bash -lc "cd $INSTALL_DIR && RAILS_ENV=production bundle exec rails db:version" 2>/dev/null; then
    log_info "Base de datos existente, ejecutando migraciones..."
    sudo -u chatwoot bash -lc "cd $INSTALL_DIR && RAILS_ENV=production bundle exec rails db:migrate"
  else
    log_info "Creando base de datos..."
    sudo -u chatwoot bash -lc "cd $INSTALL_DIR && RAILS_ENV=production bundle exec rails db:create"
    sudo -u chatwoot bash -lc "cd $INSTALL_DIR && RAILS_ENV=production bundle exec rails db:schema:load"
    sudo -u chatwoot bash -lc "cd $INSTALL_DIR && RAILS_ENV=production bundle exec rails db:seed"
  fi

  log_info "Base de datos configurada"
}

# ============================================================================
# Enable Enterprise features in database
# ============================================================================
enable_enterprise() {
  log_step "Habilitando TODAS las funciones Enterprise en la base de datos..."

  cd "$INSTALL_DIR"

  sudo -u chatwoot bash -lc "cd $INSTALL_DIR && RAILS_ENV=production bundle exec rails runner '
    # Set installation plan to enterprise
    config = InstallationConfig.find_or_create_by(name: \"INSTALLATION_PRICING_PLAN\")
    config.update!(value: \"enterprise\")

    config = InstallationConfig.find_or_create_by(name: \"INSTALLATION_PRICING_PLAN_QUANTITY\")
    config.update!(value: 100000)

    # Enable ALL features for ALL accounts
    features_to_enable = %w[
      inbound_emails channel_email channel_facebook channel_twitter
      ip_lookup disable_branding email_continuity_on_api_channel
      help_center agent_bots macros agent_management team_management
      inbox_management labels custom_attributes automations
      canned_responses integrations voice_recorder channel_website
      campaigns reports crm auto_resolve_conversations
      custom_reply_email custom_reply_domain audit_logs
      sla help_center_embedding_search linear_integration
      captain_integration custom_roles chatwoot_v4 report_v4
      shopify_integration search_with_gin inbox_view
    ]

    Account.find_each do |account|
      account.enable_features!(*features_to_enable)
      puts \"Enterprise habilitado para cuenta: #{account.name} (ID: #{account.id})\"
    end

    # Clear analytics token
    config = InstallationConfig.find_by(name: \"ANALYTICS_TOKEN\")
    config&.update!(value: nil)

    # Clear support tokens
    %w[CHATWOOT_SUPPORT_WEBSITE_TOKEN CHATWOOT_SUPPORT_SCRIPT_URL CHATWOOT_SUPPORT_IDENTIFIER_HASH].each do |name|
      c = InstallationConfig.find_by(name: name)
      c&.update!(value: nil)
    end

    puts \"\"
    puts \"========================================\"
    puts \"Enterprise Edition activado exitosamente\"
    puts \"Todas las funciones habilitadas\"
    puts \"Sin conexiones externas a Chatwoot\"
    puts \"========================================\"
  '"

  log_info "Enterprise habilitado en la base de datos"
}

# ============================================================================
# Compile assets
# ============================================================================
compile_assets() {
  log_step "Compilando assets para produccion..."

  cd "$INSTALL_DIR"

  sudo -u chatwoot bash -lc "cd $INSTALL_DIR && RAILS_ENV=production NODE_OPTIONS='--max-old-space-size=4096' bundle exec rake assets:precompile"

  log_info "Assets compilados"
}

# ============================================================================
# Setup systemd services
# ============================================================================
setup_services() {
  log_step "Configurando servicios systemd..."

  # Copy service files
  cp "$INSTALL_DIR/deployment/chatwoot-web.1.service" /etc/systemd/system/
  cp "$INSTALL_DIR/deployment/chatwoot-worker.1.service" /etc/systemd/system/
  cp "$INSTALL_DIR/deployment/chatwoot.target" /etc/systemd/system/

  # Copy sudoers config
  cp "$INSTALL_DIR/deployment/chatwoot" /etc/sudoers.d/chatwoot
  chmod 440 /etc/sudoers.d/chatwoot

  systemctl daemon-reload
  systemctl enable chatwoot.target

  log_info "Servicios systemd configurados"
}

# ============================================================================
# Setup Nginx
# ============================================================================
setup_nginx() {
  local DOMAIN="${1:-localhost}"

  log_step "Configurando Nginx para $DOMAIN..."

  cat > /etc/nginx/sites-available/chatwoot << NGINXEOF
server {
  listen 80;
  listen [::]:80;
  server_name $DOMAIN;

  # Support route - redirect to help center or custom support page
  location /support {
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Real-IP \$remote_addr;
  }

  location / {
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    client_max_body_size 0;
    proxy_read_timeout 36000s;
    proxy_redirect off;
  }
}
NGINXEOF

  ln -sf /etc/nginx/sites-available/chatwoot /etc/nginx/sites-enabled/chatwoot
  rm -f /etc/nginx/sites-enabled/default

  nginx -t && systemctl reload nginx

  log_info "Nginx configurado"
}

# ============================================================================
# Setup SSL with Let's Encrypt
# ============================================================================
setup_ssl() {
  local DOMAIN="${1:-}"
  local EMAIL="${2:-}"

  if [ -z "$DOMAIN" ] || [ "$DOMAIN" = "localhost" ]; then
    log_warn "SSL omitido - se necesita un dominio valido"
    return
  fi

  log_step "Configurando SSL para $DOMAIN..."

  certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" 2>/dev/null || {
    log_warn "Certbot fallo. Puede ejecutar manualmente: certbot --nginx -d $DOMAIN"
  }

  log_info "SSL configurado"
}

# ============================================================================
# Start services
# ============================================================================
start_services() {
  log_step "Iniciando servicios..."

  systemctl restart chatwoot.target
  systemctl restart nginx

  log_info "Servicios iniciados"
}

# ============================================================================
# Upgrade existing installation
# ============================================================================
upgrade() {
  log_step "Actualizando instalacion existente..."

  cd "$INSTALL_DIR"

  # Stop services
  systemctl stop chatwoot.target 2>/dev/null || true

  # Pull latest code
  sudo -u chatwoot git fetch origin "$REPO_BRANCH"
  sudo -u chatwoot git checkout "$REPO_BRANCH"
  sudo -u chatwoot git pull origin "$REPO_BRANCH"

  # Update dependencies
  install_app

  # Run migrations
  sudo -u chatwoot bash -lc "cd $INSTALL_DIR && RAILS_ENV=production bundle exec rails db:migrate"

  # Re-enable enterprise features
  enable_enterprise

  # Recompile assets
  compile_assets

  # Restart
  systemctl restart chatwoot.target

  log_info "Actualizacion completada"
}

# ============================================================================
# Show usage
# ============================================================================
usage() {
  echo ""
  echo "Uso: $0 [comando] [opciones]"
  echo ""
  echo "Comandos:"
  echo "  install     Instalacion completa (requiere --domain)"
  echo "  upgrade     Actualizar instalacion existente"
  echo "  enterprise  Solo habilitar Enterprise en la BD"
  echo "  ssl         Configurar SSL (requiere --domain y --email)"
  echo "  restart     Reiniciar servicios"
  echo "  status      Ver estado de servicios"
  echo ""
  echo "Opciones:"
  echo "  --domain    Dominio del servidor (ej: app.midominio.com)"
  echo "  --email     Email para SSL Let's Encrypt"
  echo "  --branch    Branch del repositorio (default: develop)"
  echo ""
  echo "Ejemplos:"
  echo "  $0 install --domain app.midominio.com --email admin@midominio.com"
  echo "  $0 upgrade"
  echo "  $0 enterprise"
  echo "  $0 ssl --domain app.midominio.com --email admin@midominio.com"
  echo ""
}

# ============================================================================
# Main
# ============================================================================
main() {
  local COMMAND="${1:-}"
  shift || true

  local DOMAIN=""
  local EMAIL=""

  # Parse options
  while [[ $# -gt 0 ]]; do
    case $1 in
      --domain) DOMAIN="$2"; shift 2 ;;
      --email) EMAIL="$2"; shift 2 ;;
      --branch) REPO_BRANCH="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  case "$COMMAND" in
    install)
      if [ -z "$DOMAIN" ]; then
        log_error "Se requiere --domain para la instalacion"
        usage
        exit 1
      fi

      check_root
      detect_os

      echo ""
      echo "============================================"
      echo "  INSTALACION ENTERPRISE INDEPENDIENTE"
      echo "  Dominio: $DOMAIN"
      echo "  Repositorio: $REPO_URL"
      echo "  Branch: $REPO_BRANCH"
      echo "============================================"
      echo ""

      install_dependencies
      install_pgvector
      install_ruby
      install_node
      create_user
      setup_postgres
      setup_redis
      setup_repo
      configure_env "$DOMAIN"
      install_app
      setup_database
      enable_enterprise
      compile_assets
      setup_services
      setup_nginx "$DOMAIN"

      if [ -n "$EMAIL" ]; then
        setup_ssl "$DOMAIN" "$EMAIL"
      fi

      start_services

      echo ""
      echo "============================================"
      echo "  INSTALACION COMPLETADA"
      echo "============================================"
      echo ""
      echo "  URL:     https://$DOMAIN"
      echo "  Soporte: https://$DOMAIN/support"
      echo ""
      echo "  Enterprise: ACTIVADO"
      echo "  Telemetria: DESHABILITADA"
      echo "  Conexiones externas: NINGUNA"
      echo ""
      echo "  Para crear admin inicial visite:"
      echo "  https://$DOMAIN"
      echo ""
      echo "============================================"
      ;;

    upgrade)
      check_root
      upgrade
      echo ""
      log_info "Actualizacion completada exitosamente"
      ;;

    enterprise)
      check_root
      enable_enterprise
      echo ""
      log_info "Enterprise habilitado en todas las cuentas"
      ;;

    ssl)
      check_root
      setup_ssl "$DOMAIN" "$EMAIL"
      ;;

    restart)
      check_root
      systemctl restart chatwoot.target
      systemctl restart nginx
      log_info "Servicios reiniciados"
      ;;

    status)
      echo ""
      systemctl status chatwoot.target --no-pager 2>/dev/null || true
      echo ""
      systemctl status chatwoot-web.1.service --no-pager 2>/dev/null || true
      echo ""
      systemctl status chatwoot-worker.1.service --no-pager 2>/dev/null || true
      ;;

    *)
      usage
      ;;
  esac
}

main "$@"
