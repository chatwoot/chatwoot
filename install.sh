#!/usr/bin/env bash
#
# Chatwoot v4.11.0 — Intelligent Installer
# Single-script automated deployment for Ubuntu 20.04 / 22.04 / 24.04 LTS
#
# Usage:
#   sudo bash install.sh                    # Interactive install
#   sudo bash install.sh --auto             # Fully automatic (no prompts)
#   sudo bash install.sh --auto --domain chat.example.com --email admin@example.com
#   sudo bash install.sh --upgrade          # Upgrade existing installation
#   sudo bash install.sh --status           # Check installation health
#
# Repository: GtrhSystems/chatwoot (custom fork)
#
set -euo pipefail

###############################################################################
# CONFIGURATION — Exact versions extracted from codebase analysis
###############################################################################
readonly INSTALLER_VERSION="1.0.0"
readonly CHATWOOT_VERSION="4.11.0"

# Runtime versions (from .ruby-version, .nvmrc, package.json, Gemfile.lock)
readonly RUBY_VERSION="3.4.4"
readonly BUNDLER_VERSION="2.5.16"
readonly NODE_MAJOR=24
readonly NODE_VERSION="24.13.0"
readonly PNPM_VERSION="10.2.0"

# Database versions (from docker-compose.production.yaml, deployment/setup_20.04.sh)
readonly PG_VERSION=16
readonly REDIS_MIN_VERSION=7

# Application paths
readonly CW_USER="chatwoot"
readonly CW_HOME="/home/${CW_USER}"
readonly CW_APP="${CW_HOME}/chatwoot"
readonly CW_CONFIG="/opt/chatwoot/config"

# Repository
readonly GIT_REPO="https://github.com/GtrhSystems/chatwoot.git"
readonly GIT_BRANCH="master"

# Logging
readonly LOG_FILE="/var/log/chatwoot-install.log"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Globals
AUTO_MODE=false
DOMAIN=""
LE_EMAIL=""
SKIP_DB=false
SKIP_WEBSERVER=false
UPGRADE_MODE=false
STATUS_MODE=false
PG_PASS=""
STEP_CURRENT=0
STEP_TOTAL=0

###############################################################################
# LOGGING & OUTPUT
###############################################################################
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

info()    { log "INFO: $*";    echo -e "${BLUE}[INFO]${NC}    $*"; }
success() { log "SUCCESS: $*"; echo -e "${GREEN}[OK]${NC}      $*"; }
warn()    { log "WARN: $*";    echo -e "${YELLOW}[WARN]${NC}    $*"; }
error()   { log "ERROR: $*";   echo -e "${RED}[ERROR]${NC}   $*"; }
fatal()   { log "FATAL: $*";   echo -e "${RED}[FATAL]${NC}   $*"; exit 1; }

# Run a command as the chatwoot user with RVM loaded.
# Uses heredoc via stdin to avoid $* quoting issues with multiline commands.
run_as_cw() {
  local rvm_src=""
  if [[ -f /usr/local/rvm/scripts/rvm ]]; then
    rvm_src="source /usr/local/rvm/scripts/rvm"
  elif [[ -f /etc/profile.d/rvm.sh ]]; then
    rvm_src="source /etc/profile.d/rvm.sh"
  elif [[ -f "${CW_HOME}/.rvm/scripts/rvm" ]]; then
    rvm_src="source ${CW_HOME}/.rvm/scripts/rvm"
  fi
  sudo -i -u "$CW_USER" bash <<RUNCMD
${rvm_src}
$1
RUNCMD
}

step() {
  STEP_CURRENT=$((STEP_CURRENT + 1))
  echo ""
  echo -e "${CYAN}${BOLD}--- Step ${STEP_CURRENT}/${STEP_TOTAL}: $* ---${NC}"
  log "STEP ${STEP_CURRENT}/${STEP_TOTAL}: $*"
}

banner() {
  echo ""
  echo -e "${BOLD}+--------------------------------------------------------------+${NC}"
  echo -e "${BOLD}|          Chatwoot v${CHATWOOT_VERSION} - Intelligent Installer             |${NC}"
  echo -e "${BOLD}|          Installer v${INSTALLER_VERSION}                                   |${NC}"
  echo -e "${BOLD}+--------------------------------------------------------------+${NC}"
  echo ""
  echo -e "  ${CYAN}Ruby:${NC}       ${RUBY_VERSION}       ${CYAN}Bundler:${NC}  ${BUNDLER_VERSION}"
  echo -e "  ${CYAN}Node.js:${NC}    ${NODE_VERSION}    ${CYAN}pnpm:${NC}     ${PNPM_VERSION}"
  echo -e "  ${CYAN}PostgreSQL:${NC} ${PG_VERSION} + pgvector  ${CYAN}Redis:${NC}    ${REDIS_MIN_VERSION}+"
  echo -e "  ${CYAN}Rails:${NC}      7.1.x          ${CYAN}Puma:${NC}     6.4.x"
  echo ""
}

###############################################################################
# ARGUMENT PARSING
###############################################################################
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --auto)       AUTO_MODE=true; shift ;;
      --domain)     DOMAIN="$2"; shift 2 ;;
      --email)      LE_EMAIL="$2"; shift 2 ;;
      --skip-db)    SKIP_DB=true; shift ;;
      --skip-web)   SKIP_WEBSERVER=true; shift ;;
      --upgrade)    UPGRADE_MODE=true; shift ;;
      --status)     STATUS_MODE=true; shift ;;
      --help|-h)    usage; exit 0 ;;
      *) fatal "Unknown option: $1. Use --help for usage." ;;
    esac
  done
}

usage() {
  cat <<'USAGE'
Usage: sudo bash install.sh [OPTIONS]

Installation:
  --auto              Fully automated mode (no interactive prompts)
  --domain DOMAIN     Domain name for SSL (e.g., chat.example.com)
  --email EMAIL       Email for Let's Encrypt SSL certificate
  --skip-db           Skip PostgreSQL & Redis installation (external services)
  --skip-web          Skip Nginx & SSL setup

Management:
  --upgrade           Upgrade existing installation to latest
  --status            Check health of current installation

Examples:
  sudo bash install.sh                                    # Interactive
  sudo bash install.sh --auto                             # Auto, no SSL
  sudo bash install.sh --auto --domain chat.example.com --email admin@example.com
  sudo bash install.sh --upgrade
  sudo bash install.sh --status
USAGE
}

###############################################################################
# PRE-FLIGHT CHECKS
###############################################################################
check_root() {
  if [[ $EUID -ne 0 ]]; then
    fatal "This script must be run as root. Use: sudo bash install.sh"
  fi
}

check_os() {
  if [[ ! -f /etc/os-release ]]; then
    fatal "Cannot detect OS. /etc/os-release not found."
  fi

  # shellcheck source=/dev/null
  source /etc/os-release

  if [[ "$ID" != "ubuntu" ]]; then
    fatal "Unsupported OS: $ID. Only Ubuntu is supported."
  fi

  case "$VERSION_ID" in
    20.04|22.04|24.04)
      success "OS: Ubuntu ${VERSION_ID} LTS (${VERSION_CODENAME})"
      ;;
    *)
      fatal "Unsupported Ubuntu version: ${VERSION_ID}. Supported: 20.04, 22.04, 24.04"
      ;;
  esac
}

check_architecture() {
  local arch
  arch=$(uname -m)
  case "$arch" in
    x86_64|amd64)
      success "Architecture: x86_64"
      ;;
    aarch64|arm64)
      success "Architecture: ARM64"
      ;;
    *)
      fatal "Unsupported architecture: $arch"
      ;;
  esac
}

check_resources() {
  local ram_mb disk_gb cpu_cores
  ram_mb=$(free -m | awk '/^Mem:/{print $2}')
  disk_gb=$(df -BG / | awk 'NR==2{print $4}' | tr -d 'G')
  cpu_cores=$(nproc)

  info "System: ${cpu_cores} CPU, ${ram_mb}MB RAM, ${disk_gb}GB disk free"

  if [[ $ram_mb -lt 1800 ]]; then
    fatal "Insufficient RAM: ${ram_mb}MB. Minimum: 2048MB (2GB)."
  elif [[ $ram_mb -lt 3800 ]]; then
    warn "Low RAM: ${ram_mb}MB. Recommended: 4096MB (4GB) for production."
  fi

  if [[ $disk_gb -lt 8 ]]; then
    fatal "Insufficient disk: ${disk_gb}GB free. Minimum: 10GB."
  elif [[ $disk_gb -lt 20 ]]; then
    warn "Low disk: ${disk_gb}GB free. Recommended: 25GB+."
  fi
}

check_ports() {
  local ports_in_use=()
  for port in 3000 80 443 5432 6379; do
    if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
      ports_in_use+=("$port")
    fi
  done

  if [[ ${#ports_in_use[@]} -gt 0 ]]; then
    warn "Ports in use: ${ports_in_use[*]} (may be existing services)"
  fi
}

check_existing_installation() {
  if [[ -d "$CW_APP" ]]; then
    if [[ "$UPGRADE_MODE" == true ]]; then
      info "Existing installation found. Proceeding with upgrade."
      return 0
    fi
    warn "Existing Chatwoot installation found at ${CW_APP}."
    if [[ "$AUTO_MODE" == true ]]; then
      info "Auto mode: switching to upgrade."
      UPGRADE_MODE=true
    else
      read -rp "Existing installation found. Upgrade it? (yes/no): " answer
      if [[ "$answer" == "yes" ]]; then
        UPGRADE_MODE=true
      else
        fatal "Aborted. Remove ${CW_APP} first or use --upgrade."
      fi
    fi
  fi
}

###############################################################################
# INTERACTIVE PROMPTS (skipped in --auto mode)
###############################################################################
prompt_configuration() {
  if [[ "$AUTO_MODE" == true ]]; then
    return 0
  fi

  echo ""
  echo -e "${BOLD}Configuration${NC}"
  echo "------------------------------------"

  if [[ "$SKIP_DB" != true ]]; then
    read -rp "Install PostgreSQL & Redis locally? (yes/no) [yes]: " db_answer
    db_answer=${db_answer:-yes}
    if [[ "$db_answer" == "no" ]]; then
      SKIP_DB=true
    fi
  fi

  if [[ "$SKIP_WEBSERVER" != true ]]; then
    read -rp "Configure domain & SSL with Nginx? (yes/no) [no]: " web_answer
    web_answer=${web_answer:-no}
    if [[ "$web_answer" == "yes" ]]; then
      if [[ -z "$DOMAIN" ]]; then
        read -rp "  Domain (e.g., chat.example.com): " DOMAIN
      fi
      if [[ -z "$LE_EMAIL" ]]; then
        read -rp "  Email for Let's Encrypt: " LE_EMAIL
      fi
    else
      SKIP_WEBSERVER=true
    fi
  fi

  echo ""
  echo -e "${BOLD}Summary${NC}"
  echo "------------------------------------"
  echo -e "  Database:   $([ "$SKIP_DB" == true ] && echo "External" || echo "Local PG${PG_VERSION} + Redis")"
  echo -e "  Webserver:  $([ "$SKIP_WEBSERVER" == true ] && echo "Skip" || echo "Nginx + SSL (${DOMAIN})")"
  echo -e "  Repository: ${GIT_REPO}"
  echo -e "  Branch:     ${GIT_BRANCH}"
  echo ""

  read -rp "Proceed? (yes/no): " confirm
  if [[ "$confirm" != "yes" ]]; then
    fatal "Installation cancelled."
  fi
}

###############################################################################
# SYSTEM DEPENDENCIES
#
# Required by (analysis of Gemfile native gems):
#   build-essential, g++, gcc, autoconf, make  -> grpc, cld3, nokogiri compilation
#   libssl-dev       -> puma (nio4r), bcrypt, openssl bindings
#   libyaml-dev      -> psych gem (YAML parsing)
#   libreadline-dev  -> Ruby readline support
#   libffi-dev       -> ffi gem (llhttp-ffi, ruby-vips FFI)
#   libxml2-dev      -> nokogiri (HTML/XML parsing, sanitization)
#   libxslt1-dev     -> nokogiri XSLT support
#   zlib1g-dev       -> nokogiri, various compression
#   liblzma-dev      -> Ruby LZMA support
#   libgmp-dev       -> Ruby bignum operations
#   libncurses5-dev  -> Ruby readline/curses
#   libgdbm-dev      -> Ruby GDBM database support
#   libpq-dev        -> pg gem (PostgreSQL adapter)
#   libvips          -> ruby-vips / image_processing gem (thumbnail generation)
#   imagemagick      -> mini_magick gem (image processing fallback)
#   patch            -> RVM ruby installation
#   file             -> MIME type detection for attachments
###############################################################################
install_system_dependencies() {
  step "Installing system dependencies"

  export DEBIAN_FRONTEND=noninteractive

  info "Updating package lists..."
  apt-get update -qq >> "$LOG_FILE" 2>&1

  info "Upgrading existing packages..."
  apt-get upgrade -y -qq >> "$LOG_FILE" 2>&1

  info "Installing build tools and libraries..."
  apt-get install -y -qq \
    git curl wget gnupg2 ca-certificates lsb-release \
    software-properties-common apt-transport-https \
    build-essential g++ gcc autoconf make \
    libssl-dev libyaml-dev libreadline-dev libffi-dev \
    libxml2-dev libxslt1-dev zlib1g-dev liblzma-dev \
    libgmp-dev libncurses5-dev libgdbm-dev \
    libpq-dev libvips imagemagick \
    file patch sudo python3-pip \
    >> "$LOG_FILE" 2>&1

  # python3-packaging (needed for version comparison in cwctl)
  # shellcheck source=/dev/null
  source /etc/os-release
  if [[ "$VERSION_ID" == "24.04" ]]; then
    apt-get install -y -qq python3-packaging >> "$LOG_FILE" 2>&1
  else
    python3 -m pip install packaging >> "$LOG_FILE" 2>&1 || true
  fi

  success "System dependencies installed"
}

###############################################################################
# NODE.JS
###############################################################################
install_nodejs() {
  step "Installing Node.js ${NODE_MAJOR}.x"

  if command -v node &>/dev/null; then
    local current_major
    current_major=$(node --version | cut -d'.' -f1 | tr -d 'v')
    if [[ "$current_major" -ge $NODE_MAJOR ]]; then
      success "Node.js $(node --version) already installed"
      ensure_pnpm
      return 0
    fi
    info "Upgrading Node.js from v${current_major} to v${NODE_MAJOR}..."
  fi

  mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor --yes -o /etc/apt/keyrings/nodesource.gpg >> "$LOG_FILE" 2>&1

  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list

  apt-get update -qq >> "$LOG_FILE" 2>&1
  apt-get install -y -qq nodejs >> "$LOG_FILE" 2>&1

  success "Node.js $(node --version) installed"
  ensure_pnpm
}

ensure_pnpm() {
  if command -v pnpm &>/dev/null; then
    local pnpm_major
    pnpm_major=$(pnpm --version 2>/dev/null | cut -d'.' -f1)
    if [[ "$pnpm_major" -ge 10 ]]; then
      success "pnpm $(pnpm --version) already installed"
      return 0
    fi
  fi

  info "Installing pnpm ${PNPM_VERSION}..."
  npm install -g "pnpm@${PNPM_VERSION}" >> "$LOG_FILE" 2>&1
  success "pnpm $(pnpm --version) installed"
}

###############################################################################
# POSTGRESQL 16 + pgvector
###############################################################################
install_postgresql() {
  if [[ "$SKIP_DB" == true ]]; then
    step "Skipping PostgreSQL (external database)"
    return 0
  fi

  step "Installing PostgreSQL ${PG_VERSION} with pgvector"

  if command -v psql &>/dev/null; then
    local pg_installed
    pg_installed=$(psql --version 2>/dev/null | grep -oP '\d+' | head -1 || echo "0")
    if [[ "$pg_installed" -ge $PG_VERSION ]]; then
      success "PostgreSQL ${pg_installed} already installed"
      ensure_postgresql_running
      configure_postgresql
      return 0
    fi
  fi

  echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" \
    > /etc/apt/sources.list.d/pgdg.list
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - >> "$LOG_FILE" 2>&1

  apt-get update -qq >> "$LOG_FILE" 2>&1
  apt-get install -y -qq \
    "postgresql-${PG_VERSION}" \
    "postgresql-${PG_VERSION}-pgvector" \
    "postgresql-client-${PG_VERSION}" \
    postgresql-contrib \
    >> "$LOG_FILE" 2>&1

  success "PostgreSQL ${PG_VERSION} with pgvector installed"
  ensure_postgresql_running
  configure_postgresql
}

ensure_postgresql_running() {
  systemctl enable postgresql >> "$LOG_FILE" 2>&1
  systemctl start postgresql >> "$LOG_FILE" 2>&1

  local retries=0
  while ! pg_isready -q 2>/dev/null; do
    retries=$((retries + 1))
    if [[ $retries -ge 30 ]]; then
      fatal "PostgreSQL failed to start within 30 seconds."
    fi
    sleep 1
  done
  success "PostgreSQL is running"
}

configure_postgresql() {
  mkdir -p "$CW_CONFIG"
  local pg_pass_file="${CW_CONFIG}/.pg_pass"

  if [[ -f "$pg_pass_file" ]]; then
    PG_PASS=$(cat "$pg_pass_file")
    info "Using existing PostgreSQL password"
  else
    PG_PASS=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)
    echo "$PG_PASS" > "$pg_pass_file"
    chmod 600 "$pg_pass_file"
    info "Generated PostgreSQL password"
  fi

  # Create user (idempotent)
  local user_exists
  user_exists=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${CW_USER}'" 2>/dev/null || echo "0")
  if [[ "$user_exists" != "1" ]]; then
    sudo -u postgres psql -c "CREATE USER ${CW_USER} CREATEDB SUPERUSER PASSWORD '${PG_PASS}';" >> "$LOG_FILE" 2>&1
    info "Created PostgreSQL user: ${CW_USER}"
  else
    sudo -u postgres psql -c "ALTER USER ${CW_USER} PASSWORD '${PG_PASS}';" >> "$LOG_FILE" 2>&1
  fi

  # Ensure template1 is UTF-8
  sudo -u postgres psql <<-PGSQL >> "$LOG_FILE" 2>&1 || true
    UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'template1';
    DROP DATABASE IF EXISTS template1;
    CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = 'UNICODE';
    UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template1';
PGSQL

  success "PostgreSQL configured"
}

###############################################################################
# REDIS
###############################################################################
install_redis() {
  if [[ "$SKIP_DB" == true ]]; then
    step "Skipping Redis (external service)"
    return 0
  fi

  step "Installing Redis"

  if command -v redis-server &>/dev/null; then
    local redis_major
    redis_major=$(redis-server --version | grep -oP 'v=\K\d+' || echo "0")
    if [[ "$redis_major" -ge $REDIS_MIN_VERSION ]]; then
      success "Redis $(redis-server --version | grep -oP 'v=\K[\d.]+') already installed"
      ensure_redis_running
      return 0
    fi
    info "Upgrading Redis to v${REDIS_MIN_VERSION}+..."
  fi

  curl -fsSL https://packages.redis.io/gpg \
    | gpg --dearmor --yes -o /usr/share/keyrings/redis-archive-keyring.gpg >> "$LOG_FILE" 2>&1
  echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/redis.list

  apt-get update -qq >> "$LOG_FILE" 2>&1
  apt-get install -y -qq redis-server >> "$LOG_FILE" 2>&1

  success "Redis $(redis-server --version | grep -oP 'v=\K[\d.]+') installed"
  ensure_redis_running
}

ensure_redis_running() {
  systemctl enable redis-server.service >> "$LOG_FILE" 2>&1
  systemctl start redis-server.service >> "$LOG_FILE" 2>&1

  local retries=0
  while ! redis-cli ping 2>/dev/null | grep -q PONG; do
    retries=$((retries + 1))
    if [[ $retries -ge 15 ]]; then
      fatal "Redis failed to start within 15 seconds."
    fi
    sleep 1
  done
  success "Redis is running"
}

###############################################################################
# RUBY via RVM
###############################################################################
install_ruby() {
  step "Installing Ruby ${RUBY_VERSION} via RVM"

  # Create system user
  if ! id -u "$CW_USER" &>/dev/null; then
    adduser --disabled-password --gecos "" "$CW_USER" >> "$LOG_FILE" 2>&1
    info "Created system user: ${CW_USER}"
  fi

  # Install RVM
  if [[ ! -d "/usr/local/rvm" ]] && [[ ! -d "${CW_HOME}/.rvm" ]]; then
    info "Installing RVM..."
    gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys \
      409B6B1796C275462A1703113804BB82D39DC0E3 \
      7D2BAF1CF37B13E2069D6956105BD0E739499BDB >> "$LOG_FILE" 2>&1 || true
    gpg2 --keyserver hkp://keyserver.ubuntu.com --recv-keys \
      409B6B1796C275462A1703113804BB82D39DC0E3 \
      7D2BAF1CF37B13E2069D6956105BD0E739499BDB >> "$LOG_FILE" 2>&1 || true
    curl -sSL https://get.rvm.io | bash -s stable >> "$LOG_FILE" 2>&1
    usermod -aG rvm "$CW_USER" 2>/dev/null || adduser "$CW_USER" rvm >> "$LOG_FILE" 2>&1 || true
    success "RVM installed"
  else
    success "RVM already present"
  fi

  # Install Ruby + Bundler
  info "Installing Ruby ${RUBY_VERSION} (this takes several minutes)..."
  run_as_cw "
rvm autolibs disable
rvm install 'ruby-${RUBY_VERSION}'
rvm use ${RUBY_VERSION} --default
gem install bundler -v '${BUNDLER_VERSION}' --no-document
" >> "$LOG_FILE" 2>&1

  # Verify
  local installed_ruby
  installed_ruby=$(run_as_cw "ruby --version" 2>/dev/null || echo "unknown")
  info "Ruby detected: ${installed_ruby}"
  if echo "$installed_ruby" | grep -q "${RUBY_VERSION}"; then
    success "Ruby ${RUBY_VERSION} + Bundler ${BUNDLER_VERSION}"
  else
    fatal "Ruby installation failed. Got: ${installed_ruby}. See ${LOG_FILE}"
  fi
}

###############################################################################
# APPLICATION CODE
###############################################################################
clone_or_update_repo() {
  step "Setting up application code"

  if [[ -d "$CW_APP" ]]; then
    if [[ "$UPGRADE_MODE" == true ]]; then
      info "Updating existing repository..."
      run_as_cw "
        cd chatwoot
        git fetch origin
        git checkout '${GIT_BRANCH}' 2>/dev/null || git checkout -b '${GIT_BRANCH}' 'origin/${GIT_BRANCH}'
        git reset --hard 'origin/${GIT_BRANCH}'
      " >> "$LOG_FILE" 2>&1
      success "Repository updated: ${GIT_BRANCH}"
    else
      success "Repository already exists"
    fi
  else
    info "Cloning repository..."
    run_as_cw "
      git clone '${GIT_REPO}' chatwoot
      cd chatwoot
      git checkout '${GIT_BRANCH}'
    " >> "$LOG_FILE" 2>&1
    success "Repository cloned: ${GIT_BRANCH}"
  fi
}

install_app_dependencies() {
  step "Installing application dependencies"

  info "bundle install (this takes several minutes)..."
  run_as_cw "
    cd chatwoot
    bundle config set --local deployment false
    bundle config set --local without 'development test'
    bundle install --jobs $(nproc)
  " >> "$LOG_FILE" 2>&1
  success "Ruby gems installed"

  info "pnpm install..."
  run_as_cw "
    cd chatwoot
    pnpm install --frozen-lockfile 2>/dev/null || pnpm install
  " >> "$LOG_FILE" 2>&1
  success "JavaScript packages installed"
}

###############################################################################
# ENVIRONMENT CONFIGURATION
#
# Generates all secrets automatically:
# - SECRET_KEY_BASE (64-char hex for Rails signed cookies)
# - ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY (32-char for MFA/2FA encryption)
# - ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY (32-char for deterministic encryption)
# - ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT (32-char salt)
###############################################################################
configure_environment() {
  step "Configuring environment"

  local env_file="${CW_APP}/.env"

  # Preserve existing config on upgrade
  if [[ "$UPGRADE_MODE" == true ]] && [[ -f "$env_file" ]]; then
    # Only fix defaults that should have been replaced
    if grep -q "replace_with_lengthy_secure_hex" "$env_file" 2>/dev/null; then
      local new_secret
      new_secret=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 64)
      sed -i "s/SECRET_KEY_BASE=.*/SECRET_KEY_BASE=${new_secret}/" "$env_file"
      info "Fixed default SECRET_KEY_BASE"
    fi
    success "Existing .env preserved (upgrade mode)"
    return 0
  fi

  # Generate all secrets
  local secret_key encryption_pk encryption_dk encryption_salt
  secret_key=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 64)
  encryption_pk=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)
  encryption_dk=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)
  encryption_salt=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)

  local frontend_url="http://0.0.0.0:3000"
  if [[ -n "$DOMAIN" ]]; then
    frontend_url="https://${DOMAIN}"
  fi

  local pg_host="localhost" pg_user="${CW_USER}" pg_pass_val="${PG_PASS}" redis_url="redis://localhost:6379"
  if [[ "$SKIP_DB" == true ]]; then
    pg_host="" pg_user="" pg_pass_val="" redis_url=""
    warn "Database settings empty. Configure .env manually for external services."
  fi

  sudo -i -u "$CW_USER" bash -c "cat > '${env_file}'" <<ENVFILE
# Chatwoot v${CHATWOOT_VERSION} - Generated $(date -Iseconds)
# Installer v${INSTALLER_VERSION}

# === CORE ===
SECRET_KEY_BASE=${secret_key}
FRONTEND_URL=${frontend_url}
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
LOG_LEVEL=info
FORCE_SSL=false

# === Active Record Encryption (MFA/2FA) ===
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=${encryption_pk}
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=${encryption_dk}
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=${encryption_salt}

# === DATABASE ===
POSTGRES_HOST=${pg_host}
POSTGRES_USERNAME=${pg_user}
POSTGRES_PASSWORD=${pg_pass_val}
RAILS_MAX_THREADS=5

# === REDIS ===
REDIS_URL=${redis_url}
REDIS_PASSWORD=

# === EMAIL (configure for production) ===
MAILER_SENDER_EMAIL=Chatwoot <noreply@${DOMAIN:-localhost}>
SMTP_DOMAIN=${DOMAIN:-localhost}
SMTP_ADDRESS=
SMTP_PORT=587
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_AUTHENTICATION=login
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_OPENSSL_VERIFY_MODE=peer

# === STORAGE ===
ACTIVE_STORAGE_SERVICE=local

# === FEATURES ===
ENABLE_ACCOUNT_SIGNUP=false
ENABLE_PUSH_RELAY_SERVER=false

# === SIDEKIQ ===
SIDEKIQ_CONCURRENCY=10

# === INSTALLATION ===
INSTALLATION_ENV=linux_script
ENVFILE

  chmod 600 "$env_file"
  chown "${CW_USER}:${CW_USER}" "$env_file"
  success "Environment configured (all secrets auto-generated)"
}

###############################################################################
# DIRECTORIES
# Creates tmp/pids (fixes Puma Errno::ENOENT on server.pid)
###############################################################################
prepare_directories() {
  step "Preparing application directories"

  run_as_cw "
    cd chatwoot
    mkdir -p tmp/pids tmp/cache tmp/sockets log storage
  " >> "$LOG_FILE" 2>&1

  success "Directories ready (tmp/pids, tmp/cache, log, storage)"
}

###############################################################################
# ASSET COMPILATION
###############################################################################
compile_assets() {
  step "Compiling assets (this takes several minutes)"

  info "rake assets:precompile..."
  run_as_cw "
    cd chatwoot
    RAILS_ENV=production \
    NODE_OPTIONS='--max-old-space-size=4096' \
    SECRET_KEY_BASE=precompile_placeholder \
    bundle exec rake assets:precompile
  " >> "$LOG_FILE" 2>&1

  success "Assets compiled"
}

###############################################################################
# DATABASE MIGRATIONS
###############################################################################
run_database_migrations() {
  if [[ "$SKIP_DB" == true ]]; then
    step "Skipping database migrations (external database)"
    warn "After configuring .env, run:"
    warn "  cd ${CW_APP} && RAILS_ENV=production POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare"
    return 0
  fi

  step "Running database migrations"

  info "db:chatwoot_prepare (create + migrate + seed)..."
  run_as_cw "
    cd chatwoot
    RAILS_ENV=production \
    POSTGRES_STATEMENT_TIMEOUT=600s \
    bundle exec rails db:chatwoot_prepare
  " >> "$LOG_FILE" 2>&1

  success "Database ready"
}

###############################################################################
# NGINX & SSL
###############################################################################
install_nginx_ssl() {
  if [[ "$SKIP_WEBSERVER" == true ]] || [[ -z "$DOMAIN" ]]; then
    step "Skipping Nginx & SSL"
    return 0
  fi

  step "Installing Nginx & SSL for ${DOMAIN}"

  apt-get install -y -qq nginx nginx-full certbot python3-certbot-nginx >> "$LOG_FILE" 2>&1
  success "Nginx & Certbot installed"

  info "Obtaining SSL certificate..."
  certbot certonly --non-interactive --agree-tos --nginx \
    -m "${LE_EMAIL}" -d "${DOMAIN}" >> "$LOG_FILE" 2>&1
  success "SSL certificate obtained"

  if [[ ! -f /etc/ssl/dhparam ]]; then
    curl -s https://ssl-config.mozilla.org/ffdhe4096.txt >> /etc/ssl/dhparam 2>/dev/null || true
  fi

  # Write nginx config (uses heredoc with variable expansion)
  cat > /etc/nginx/sites-available/chatwoot <<NGINX_CONF
upstream chatwoot_backend {
  zone upstreams 64K;
  server 127.0.0.1:3000;
  keepalive 32;
}

map \$http_upgrade \$connection_upgrade {
  default upgrade;
  '' close;
}

server {
  listen 80;
  listen [::]:80;
  server_name ${DOMAIN};
  return 301 https://\$host\$request_uri;
}

server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  server_name ${DOMAIN};
  underscores_in_headers on;

  access_log /var/log/nginx/chatwoot_access.log;
  error_log  /var/log/nginx/chatwoot_error.log;

  ssl_certificate     /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
  ssl_prefer_server_ciphers off;
  ssl_session_cache shared:SSL:10m;
  ssl_session_timeout 1d;
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

  location / {
    proxy_pass http://chatwoot_backend;
    proxy_redirect off;
    proxy_pass_header Authorization;
    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-Ssl on;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$connection_upgrade;
    client_max_body_size 0;
    proxy_read_timeout 36000s;
  }
}
NGINX_CONF

  rm -f /etc/nginx/sites-enabled/default
  ln -sf /etc/nginx/sites-available/chatwoot /etc/nginx/sites-enabled/chatwoot

  nginx -t >> "$LOG_FILE" 2>&1
  systemctl enable nginx >> "$LOG_FILE" 2>&1
  systemctl restart nginx >> "$LOG_FILE" 2>&1

  success "Nginx configured with SSL for ${DOMAIN}"
}

###############################################################################
# SYSTEMD SERVICES
#
# Paths are computed from RUBY_VERSION to ensure they match the installed ruby.
# The web service runs: bin/rails server -p 3000 -e production
# The worker runs: dotenv bundle exec sidekiq -C config/sidekiq.yml
# Worker has MemoryMax=1.2G to prevent OOM.
###############################################################################
configure_systemd() {
  step "Configuring systemd services"

  local ruby_bin="${CW_HOME}/.rvm/gems/ruby-${RUBY_VERSION}/bin"
  local ruby_global="${CW_HOME}/.rvm/gems/ruby-${RUBY_VERSION}@global/bin"
  local ruby_base="${CW_HOME}/.rvm/rubies/ruby-${RUBY_VERSION}/bin"
  local rvm_bin="${CW_HOME}/.rvm/bin"
  local sys_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  local full_path="${ruby_bin}:${ruby_global}:${ruby_base}:${rvm_bin}:${sys_path}"

  cat > /etc/systemd/system/chatwoot-web.1.service <<SVCFILE
[Unit]
Description=Chatwoot Web Server
Requires=network.target
After=network.target postgresql.service redis-server.service
PartOf=chatwoot.target

[Service]
Type=simple
User=${CW_USER}
WorkingDirectory=${CW_APP}
ExecStart=/bin/bash -lc 'bin/rails server -p \$PORT -e \$RAILS_ENV'
Restart=always
RestartSec=3
TimeoutStopSec=30
KillMode=mixed
StandardInput=null
SyslogIdentifier=%p
Environment="PATH=${full_path}"
Environment="PORT=3000"
Environment="RAILS_ENV=production"
Environment="NODE_ENV=production"
Environment="RAILS_LOG_TO_STDOUT=true"
Environment="GEM_HOME=${CW_HOME}/.rvm/gems/ruby-${RUBY_VERSION}"
Environment="GEM_PATH=${CW_HOME}/.rvm/gems/ruby-${RUBY_VERSION}:${CW_HOME}/.rvm/gems/ruby-${RUBY_VERSION}@global"

[Install]
WantedBy=chatwoot.target
SVCFILE

  cat > /etc/systemd/system/chatwoot-worker.1.service <<SVCFILE
[Unit]
Description=Chatwoot Sidekiq Worker
Requires=network.target
After=network.target postgresql.service redis-server.service
PartOf=chatwoot.target

[Service]
Type=simple
User=${CW_USER}
WorkingDirectory=${CW_APP}
ExecStart=/bin/bash -lc 'dotenv bundle exec sidekiq -C config/sidekiq.yml'
Restart=always
RestartSec=3
TimeoutStopSec=30
KillMode=mixed
StandardInput=null
SyslogIdentifier=%p
MemoryMax=1.2G
MemoryHigh=infinity
MemorySwapMax=0
OOMPolicy=stop
Environment="PATH=${full_path}"
Environment="PORT=3000"
Environment="RAILS_ENV=production"
Environment="NODE_ENV=production"
Environment="RAILS_LOG_TO_STDOUT=true"
Environment="GEM_HOME=${CW_HOME}/.rvm/gems/ruby-${RUBY_VERSION}"
Environment="GEM_PATH=${CW_HOME}/.rvm/gems/ruby-${RUBY_VERSION}:${CW_HOME}/.rvm/gems/ruby-${RUBY_VERSION}@global"

[Install]
WantedBy=chatwoot.target
SVCFILE

  cat > /etc/systemd/system/chatwoot.target <<SVCFILE
[Unit]
Description=Chatwoot
Wants=chatwoot-web.1.service chatwoot-worker.1.service

[Install]
WantedBy=multi-user.target
SVCFILE

  cat > /etc/sudoers.d/chatwoot <<SUDOERS
%${CW_USER} ALL=NOPASSWD: /bin/systemctl start chatwoot.target
%${CW_USER} ALL=NOPASSWD: /bin/systemctl stop chatwoot.target
%${CW_USER} ALL=NOPASSWD: /bin/systemctl restart chatwoot.target
%${CW_USER} ALL=NOPASSWD: /usr/local/bin/cwctl
SUDOERS
  chmod 440 /etc/sudoers.d/chatwoot

  # Install cwctl
  if [[ -f "${CW_APP}/deployment/setup_20.04.sh" ]]; then
    cp "${CW_APP}/deployment/setup_20.04.sh" /usr/local/bin/cwctl
    chmod +x /usr/local/bin/cwctl
  fi

  systemctl daemon-reload
  systemctl enable chatwoot.target >> "$LOG_FILE" 2>&1
  systemctl start chatwoot.target >> "$LOG_FILE" 2>&1

  success "Systemd services configured and started"
}

###############################################################################
# POST-INSTALL VERIFICATION
###############################################################################
verify_installation() {
  step "Verifying installation"

  sleep 5

  local all_ok=true

  if systemctl is-active --quiet chatwoot-web.1.service; then
    success "Puma web server: running"
  else
    error "Puma web server: NOT running"
    warn "  Check: journalctl -u chatwoot-web.1.service --no-pager -n 30"
    all_ok=false
  fi

  if systemctl is-active --quiet chatwoot-worker.1.service; then
    success "Sidekiq worker: running"
  else
    error "Sidekiq worker: NOT running"
    warn "  Check: journalctl -u chatwoot-worker.1.service --no-pager -n 30"
    all_ok=false
  fi

  # Wait a bit more then check HTTP
  sleep 5
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:3000 2>/dev/null || echo "000")

  if [[ "$http_code" -ge 200 ]] && [[ "$http_code" -lt 500 ]]; then
    success "HTTP response: ${http_code}"
  elif [[ "$http_code" == "000" ]]; then
    warn "HTTP: no response yet (server may still be booting)"
  else
    warn "HTTP: ${http_code} (may still be initializing)"
  fi

  if [[ "$SKIP_DB" != true ]]; then
    if pg_isready -q 2>/dev/null; then
      success "PostgreSQL: running"
    else
      error "PostgreSQL: NOT running"; all_ok=false
    fi

    if redis-cli ping 2>/dev/null | grep -q PONG; then
      success "Redis: running"
    else
      error "Redis: NOT running"; all_ok=false
    fi
  fi

  if [[ "$SKIP_WEBSERVER" != true ]] && [[ -n "$DOMAIN" ]]; then
    if systemctl is-active --quiet nginx; then
      success "Nginx: running"
    else
      error "Nginx: NOT running"; all_ok=false
    fi
  fi

  if [[ "$all_ok" != true ]]; then
    warn "Some services failed. See: ${LOG_FILE}"
  fi
}

###############################################################################
# STATUS CHECK
###############################################################################
run_status_check() {
  banner

  echo -e "${BOLD}Health Check${NC}"
  echo "------------------------------------"
  echo ""

  # shellcheck source=/dev/null
  source /etc/os-release 2>/dev/null || true
  echo -e "  ${CYAN}OS:${NC}         ${PRETTY_NAME:-unknown}"

  local ruby_ver node_ver pnpm_ver pg_ver redis_ver cw_ver
  ruby_ver=$(run_as_cw "ruby --version" 2>/dev/null || echo "not installed")
  node_ver=$(node --version 2>/dev/null || echo "not installed")
  pnpm_ver=$(pnpm --version 2>/dev/null || echo "not installed")
  pg_ver=$(psql --version 2>/dev/null || echo "not installed")
  redis_ver=$(redis-server --version 2>/dev/null | grep -oP 'v=\K[\d.]+' || echo "not installed")

  echo -e "  ${CYAN}Ruby:${NC}       ${ruby_ver}"
  echo -e "  ${CYAN}Node.js:${NC}    ${node_ver}"
  echo -e "  ${CYAN}pnpm:${NC}       ${pnpm_ver}"
  echo -e "  ${CYAN}PostgreSQL:${NC} ${pg_ver}"
  echo -e "  ${CYAN}Redis:${NC}      ${redis_ver}"

  if [[ -f "${CW_APP}/package.json" ]]; then
    cw_ver=$(grep '"version"' "${CW_APP}/package.json" 2>/dev/null | head -1 | grep -oP '"\K[\d.]+' || echo "unknown")
    echo -e "  ${CYAN}Chatwoot:${NC}   ${cw_ver}"
  fi

  echo ""
  echo -e "${BOLD}Services${NC}"
  echo "------------------------------------"
  echo ""

  for svc in chatwoot-web.1 chatwoot-worker.1 postgresql redis-server nginx; do
    local status
    if systemctl is-active --quiet "${svc}.service" 2>/dev/null || systemctl is-active --quiet "${svc}" 2>/dev/null; then
      status="${GREEN}running${NC}"
    else
      status="${RED}stopped${NC}"
    fi
    printf "  %-28s %b\n" "${svc}:" "$status"
  done

  echo ""
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://localhost:3000 2>/dev/null || echo "000")
  echo -e "  ${CYAN}HTTP localhost:3000:${NC} ${http_code}"
  echo ""

  exit 0
}

###############################################################################
# COMPLETION MESSAGE
###############################################################################
print_completion() {
  local access_url
  if [[ -n "$DOMAIN" ]]; then
    access_url="https://${DOMAIN}"
  else
    local public_ip
    public_ip=$(curl -s --max-time 5 http://checkip.amazonaws.com 2>/dev/null || echo "YOUR_SERVER_IP")
    access_url="http://${public_ip}:3000"
  fi

  echo ""
  echo -e "${GREEN}${BOLD}+--------------------------------------------------------------+${NC}"
  echo -e "${GREEN}${BOLD}|              Installation Complete!                           |${NC}"
  echo -e "${GREEN}${BOLD}+--------------------------------------------------------------+${NC}"
  echo ""
  echo -e "  ${BOLD}Access:${NC}  ${access_url}"
  echo -e "  ${BOLD}Version:${NC} Chatwoot v${CHATWOOT_VERSION}"
  echo -e "  ${BOLD}App:${NC}     ${CW_APP}"
  echo -e "  ${BOLD}Config:${NC}  ${CW_APP}/.env"
  echo -e "  ${BOLD}Log:${NC}     ${LOG_FILE}"
  echo ""
  echo -e "  ${BOLD}Commands:${NC}"
  echo -e "    systemctl status chatwoot.target            # Status"
  echo -e "    systemctl restart chatwoot.target           # Restart"
  echo -e "    journalctl -u chatwoot-web.1.service -f     # Web logs"
  echo -e "    journalctl -u chatwoot-worker.1.service -f  # Worker logs"
  echo -e "    sudo bash install.sh --status               # Health check"
  echo ""

  if [[ "$SKIP_DB" == true ]]; then
    echo -e "  ${YELLOW}NOTE: Configure database in ${CW_APP}/.env, then:${NC}"
    echo -e "    cd ${CW_APP} && RAILS_ENV=production POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare"
    echo ""
  fi

  if [[ -z "$DOMAIN" ]]; then
    echo -e "  ${YELLOW}To add SSL:${NC}"
    echo -e "    sudo bash install.sh --auto --domain YOUR_DOMAIN --email YOUR_EMAIL"
    echo ""
  fi
}

###############################################################################
# UPGRADE FLOW
###############################################################################
run_upgrade() {
  STEP_TOTAL=9

  info "Starting upgrade to Chatwoot v${CHATWOOT_VERSION}..."
  echo ""

  clone_or_update_repo
  install_system_dependencies
  install_nodejs
  install_ruby
  install_app_dependencies
  prepare_directories
  compile_assets

  step "Running database migrations"
  run_as_cw "
    cd chatwoot
    RAILS_ENV=production \
    POSTGRES_STATEMENT_TIMEOUT=600s \
    bundle exec rails db:migrate
  " >> "$LOG_FILE" 2>&1
  success "Migrations complete"

  configure_systemd
  verify_installation
  print_completion
}

###############################################################################
# FRESH INSTALL FLOW
###############################################################################
run_install() {
  STEP_TOTAL=13

  install_system_dependencies
  install_nodejs
  install_postgresql
  install_redis
  install_ruby
  clone_or_update_repo
  install_app_dependencies
  configure_environment
  prepare_directories
  compile_assets
  run_database_migrations
  install_nginx_ssl
  configure_systemd
  verify_installation
  print_completion
}

###############################################################################
# ENTRYPOINT
###############################################################################
main() {
  parse_args "$@"

  mkdir -p "$(dirname "$LOG_FILE")"
  touch "$LOG_FILE"

  if [[ "$STATUS_MODE" == true ]]; then
    run_status_check
  fi

  check_root
  banner
  echo -e "${BOLD}Pre-flight Checks${NC}"
  echo "------------------------------------"
  check_os
  check_architecture
  check_resources
  check_ports
  check_existing_installation

  if [[ "$UPGRADE_MODE" == true ]]; then
    run_upgrade
    exit 0
  fi

  prompt_configuration
  run_install
  exit 0
}

main "$@"
