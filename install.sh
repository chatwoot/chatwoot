#!/usr/bin/env bash
#
# Chatwoot v4.11.0 — Instalador Dictatorial
# IMPONE las versiones exactas. Elimina todo lo que estorbe. Sin excepciones.
#
# Usage:
#   sudo bash install.sh --auto --domain chat.example.com --email admin@example.com
#   sudo bash install.sh --upgrade
#   sudo bash install.sh --status
#
set -euo pipefail

###############################################################################
# VERSIONES OBLIGATORIAS — Extraídas del codebase. NO negociables.
###############################################################################
readonly INSTALLER_VERSION="2.0.0"
readonly CHATWOOT_VERSION="4.11.0"

readonly RUBY_VERSION="3.4.4"
readonly BUNDLER_VERSION="2.5.16"
readonly NODE_MAJOR=24
readonly PNPM_VERSION="10.2.0"
readonly PG_VERSION=16
readonly REDIS_MIN_VERSION=7

readonly CW_USER="chatwoot"
readonly CW_HOME="/home/${CW_USER}"
readonly CW_APP="${CW_HOME}/chatwoot"
readonly CW_CONFIG="/opt/chatwoot/config"
readonly GIT_REPO="https://github.com/GtrhSystems/chatwoot.git"
readonly GIT_BRANCH="master"
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
# LOGGING
###############################################################################
log()     { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }
info()    { log "INFO: $*";    echo -e "${BLUE}[INFO]${NC}    $*"; }
success() { log "OK: $*";      echo -e "${GREEN}[OK]${NC}      $*"; }
warn()    { log "WARN: $*";    echo -e "${YELLOW}[WARN]${NC}    $*"; }
error()   { log "ERROR: $*";   echo -e "${RED}[ERROR]${NC}   $*"; }
fatal()   { log "FATAL: $*";   echo -e "${RED}[FATAL]${NC}   $*"; exit 1; }

step() {
  STEP_CURRENT=$((STEP_CURRENT + 1))
  echo ""
  echo -e "${CYAN}${BOLD}--- Paso ${STEP_CURRENT}/${STEP_TOTAL}: $* ---${NC}"
  log "STEP ${STEP_CURRENT}/${STEP_TOTAL}: $*"
}

banner() {
  echo ""
  echo -e "${BOLD}+--------------------------------------------------------------+${NC}"
  echo -e "${BOLD}|     Chatwoot v${CHATWOOT_VERSION} — Instalador Dictatorial v${INSTALLER_VERSION}       |${NC}"
  echo -e "${BOLD}+--------------------------------------------------------------+${NC}"
  echo ""
  echo -e "  ${CYAN}Ruby:${NC}       ${RUBY_VERSION}       ${CYAN}Bundler:${NC}  ${BUNDLER_VERSION}"
  echo -e "  ${CYAN}Node.js:${NC}    ${NODE_MAJOR}.x          ${CYAN}pnpm:${NC}     ${PNPM_VERSION}"
  echo -e "  ${CYAN}PostgreSQL:${NC} ${PG_VERSION} + pgvector  ${CYAN}Redis:${NC}    ${REDIS_MIN_VERSION}+"
  echo ""
  echo -e "  ${YELLOW}Modo: IMPOSICIÓN TOTAL de versiones exactas${NC}"
  echo ""
}

###############################################################################
# EJECUTAR COMO USUARIO CHATWOOT — Con RVM forzado
###############################################################################
run_as_cw() {
  sudo -i -u "$CW_USER" bash <<RUNCMD
# Forzar carga de RVM — buscar en TODOS los posibles paths
for rvm_script in /usr/local/rvm/scripts/rvm /etc/profile.d/rvm.sh "${CW_HOME}/.rvm/scripts/rvm"; do
  if [[ -f "\$rvm_script" ]]; then
    source "\$rvm_script"
    break
  fi
done
# Forzar la versión de Ruby (si RVM está disponible)
type rvm &>/dev/null && rvm use ${RUBY_VERSION} --default &>/dev/null || true
$1
RUNCMD
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
      *) fatal "Opción desconocida: $1. Usa --help." ;;
    esac
  done
}

usage() {
  cat <<'USAGE'
Usage: sudo bash install.sh [OPTIONS]

  --auto              Modo automático (sin prompts)
  --domain DOMAIN     Dominio para SSL
  --email EMAIL       Email para Let's Encrypt
  --skip-db           No instalar PostgreSQL/Redis (servicios externos)
  --skip-web          No instalar Nginx/SSL
  --upgrade           Actualizar instalación existente
  --status            Verificar salud de la instalación

Ejemplo:
  sudo bash install.sh --auto --domain chat.example.com --email admin@example.com
USAGE
}

###############################################################################
# VERIFICACIONES PREVIAS
###############################################################################
check_root() {
  [[ $EUID -eq 0 ]] || fatal "Ejecuta como root: sudo bash install.sh"
}

check_os() {
  [[ -f /etc/os-release ]] || fatal "No se detecta el OS."
  # shellcheck source=/dev/null
  source /etc/os-release
  [[ "$ID" == "ubuntu" ]] || fatal "Solo Ubuntu soportado. Detectado: $ID"
  case "$VERSION_ID" in
    20.04|22.04|24.04) success "OS: Ubuntu ${VERSION_ID} LTS" ;;
    *) fatal "Ubuntu ${VERSION_ID} no soportado. Solo: 20.04, 22.04, 24.04" ;;
  esac
}

check_resources() {
  local ram_mb disk_gb
  ram_mb=$(free -m | awk '/^Mem:/{print $2}')
  disk_gb=$(df -BG / | awk 'NR==2{print $4}' | tr -d 'G')
  info "Sistema: $(nproc) CPU, ${ram_mb}MB RAM, ${disk_gb}GB disco libre"
  [[ $ram_mb -ge 1800 ]] || fatal "RAM insuficiente: ${ram_mb}MB. Mínimo: 2GB."
  [[ $disk_gb -ge 8 ]] || fatal "Disco insuficiente: ${disk_gb}GB libre. Mínimo: 10GB."
}

check_existing_installation() {
  if [[ -d "$CW_APP" ]]; then
    if [[ "$UPGRADE_MODE" == true ]]; then
      info "Instalación existente encontrada. Modo upgrade."
      return 0
    fi
    if [[ "$AUTO_MODE" == true ]]; then
      info "Instalación existente encontrada. Auto-switch a upgrade."
      UPGRADE_MODE=true
    else
      read -rp "Instalación existente encontrada. ¿Actualizar? (si/no): " answer
      [[ "$answer" == "si" ]] && UPGRADE_MODE=true || fatal "Abortado."
    fi
  fi
}

prompt_configuration() {
  if [[ "$AUTO_MODE" == true ]]; then return 0; fi
  echo ""
  echo -e "${BOLD}Configuración${NC}"
  echo "------------------------------------"
  if [[ "$SKIP_DB" != true ]]; then
    read -rp "¿Instalar PostgreSQL y Redis localmente? (si/no) [si]: " db_answer
    [[ "${db_answer:-si}" == "no" ]] && SKIP_DB=true
  fi
  if [[ "$SKIP_WEBSERVER" != true ]]; then
    read -rp "¿Configurar dominio y SSL con Nginx? (si/no) [no]: " web_answer
    if [[ "${web_answer:-no}" == "si" ]]; then
      [[ -z "$DOMAIN" ]] && read -rp "  Dominio: " DOMAIN
      [[ -z "$LE_EMAIL" ]] && read -rp "  Email para Let's Encrypt: " LE_EMAIL
    else
      SKIP_WEBSERVER=true
    fi
  fi
  read -rp "¿Continuar? (si/no): " confirm
  [[ "$confirm" == "si" ]] || fatal "Instalación cancelada."
}

###############################################################################
# PASO 1: PURGAR TODO LO QUE ESTORBE
#
# Filosofía: Este instalador SABE qué necesita. Todo lo demás SOBRA.
# Elimina: system ruby, rbenv, versiones antiguas de node, etc.
###############################################################################
purge_conflicting_software() {
  step "Eliminando software conflictivo"

  export DEBIAN_FRONTEND=noninteractive

  # ── ELIMINAR RUBY DEL SISTEMA ──
  # El paquete ruby-dev/ruby instala Ruby del sistema (ej: 3.2.3 en Ubuntu 24.04)
  # que luego 'ruby --version' encuentra ANTES que el de RVM.
  # Lo eliminamos SIN piedad.
  info "Eliminando Ruby del sistema (si existe)..."
  apt-get purge -y ruby ruby-dev ruby-full ruby-bundler ruby3.* 2>/dev/null >> "$LOG_FILE" 2>&1 || true
  apt-get autoremove -y 2>/dev/null >> "$LOG_FILE" 2>&1 || true

  # Eliminar rbenv si existe (solo usamos RVM)
  if [[ -d "${CW_HOME}/.rbenv" ]]; then
    info "Eliminando rbenv..."
    rm -rf "${CW_HOME}/.rbenv"
  fi
  if [[ -d "/root/.rbenv" ]]; then
    rm -rf "/root/.rbenv"
  fi

  # Eliminar cualquier binario ruby suelto del sistema que NO sea de RVM
  for ruby_bin in /usr/bin/ruby /usr/local/bin/ruby /usr/bin/ruby3*; do
    if [[ -f "$ruby_bin" ]] || [[ -L "$ruby_bin" ]]; then
      # No tocar si es symlink a RVM
      if ! readlink -f "$ruby_bin" 2>/dev/null | grep -q rvm; then
        info "Eliminando $ruby_bin (no es de RVM)"
        rm -f "$ruby_bin"
      fi
    fi
  done

  # Eliminar binarios de bundler del sistema
  for bundler_bin in /usr/bin/bundler /usr/local/bin/bundler /usr/bin/bundle /usr/local/bin/bundle; do
    if [[ -f "$bundler_bin" ]] || [[ -L "$bundler_bin" ]]; then
      if ! readlink -f "$bundler_bin" 2>/dev/null | grep -q rvm; then
        rm -f "$bundler_bin"
      fi
    fi
  done

  # ── ELIMINAR NODE.JS ANTIGUO ──
  # Si existe node pero no es la versión correcta, eliminarlo
  if command -v node &>/dev/null; then
    local current_node_major
    current_node_major=$(node --version 2>/dev/null | cut -d'.' -f1 | tr -d 'v' || echo "0")
    if [[ "$current_node_major" -ne $NODE_MAJOR ]]; then
      info "Eliminando Node.js v${current_node_major} (necesitamos v${NODE_MAJOR})..."
      apt-get purge -y nodejs npm 2>/dev/null >> "$LOG_FILE" 2>&1 || true
      rm -f /etc/apt/sources.list.d/nodesource*.list 2>/dev/null || true
      rm -f /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx 2>/dev/null || true
    fi
  fi

  # ── ELIMINAR pnpm global viejo ──
  if command -v pnpm &>/dev/null; then
    local current_pnpm
    current_pnpm=$(pnpm --version 2>/dev/null || echo "0.0.0")
    if [[ "$current_pnpm" != "$PNPM_VERSION" ]]; then
      info "Eliminando pnpm ${current_pnpm} (necesitamos ${PNPM_VERSION})..."
      npm uninstall -g pnpm 2>/dev/null >> "$LOG_FILE" 2>&1 || true
      rm -f /usr/local/bin/pnpm /usr/local/bin/pnpx 2>/dev/null || true
    fi
  fi

  # ── LIMPIAR CACHÉ DE APT ──
  apt-get autoremove -y 2>/dev/null >> "$LOG_FILE" 2>&1 || true

  success "Software conflictivo eliminado"
}

###############################################################################
# PASO 2: DEPENDENCIAS DEL SISTEMA
# NOTA: NO incluye ruby-dev ni ningún paquete que instale Ruby del sistema
###############################################################################
install_system_dependencies() {
  step "Instalando dependencias del sistema"

  export DEBIAN_FRONTEND=noninteractive

  info "Actualizando paquetes..."
  apt-get update -qq >> "$LOG_FILE" 2>&1
  apt-get upgrade -y -qq >> "$LOG_FILE" 2>&1

  # LISTA CERRADA — Solo lo que Chatwoot necesita para compilar gems nativos
  # SIN ruby-dev, SIN ruby, SIN nada que traiga Ruby del sistema
  info "Instalando dependencias de compilación..."
  apt-get install -y -qq \
    git curl wget gnupg2 ca-certificates lsb-release \
    software-properties-common apt-transport-https \
    build-essential g++ gcc autoconf make cmake pkg-config \
    libssl-dev libyaml-dev libreadline-dev libffi-dev \
    libxml2-dev libxslt1-dev zlib1g-dev liblzma-dev \
    libgmp-dev libncurses5-dev libgdbm-dev \
    libpq-dev libvips imagemagick \
    file patch sudo \
    >> "$LOG_FILE" 2>&1

  # ── VERIFICAR que NO se coló Ruby del sistema ──
  if dpkg -l ruby 2>/dev/null | grep -q "^ii"; then
    warn "ruby del sistema se coló como dependencia. Eliminando..."
    apt-get purge -y ruby ruby-dev 2>/dev/null >> "$LOG_FILE" 2>&1 || true
  fi

  success "Dependencias del sistema instaladas (sin Ruby del sistema)"
}

###############################################################################
# PASO 3: NODE.JS — Versión EXACTA
###############################################################################
install_nodejs() {
  step "Instalando Node.js v${NODE_MAJOR} (obligatorio)"

  # Verificar si ya está la versión correcta
  if command -v node &>/dev/null; then
    local current_major
    current_major=$(node --version | cut -d'.' -f1 | tr -d 'v')
    if [[ "$current_major" -eq $NODE_MAJOR ]]; then
      success "Node.js $(node --version) — versión correcta confirmada"
      install_pnpm
      return 0
    fi
    # Versión incorrecta: ya fue purgada en purge_conflicting_software
    fatal "Node.js versión incorrecta persiste: v${current_major}. Algo falló en la purga."
  fi

  # Instalar Node.js desde NodeSource
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor --yes -o /etc/apt/keyrings/nodesource.gpg >> "$LOG_FILE" 2>&1

  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
    > /etc/apt/sources.list.d/nodesource.list

  apt-get update -qq >> "$LOG_FILE" 2>&1
  apt-get install -y -qq nodejs >> "$LOG_FILE" 2>&1

  # ── VERIFICACIÓN OBLIGATORIA ──
  if ! command -v node &>/dev/null; then
    fatal "Node.js no se instaló. Revisa ${LOG_FILE}"
  fi
  local installed_major
  installed_major=$(node --version | cut -d'.' -f1 | tr -d 'v')
  if [[ "$installed_major" -ne $NODE_MAJOR ]]; then
    fatal "Node.js se instaló pero es v${installed_major}, necesitamos v${NODE_MAJOR}. Inaceptable."
  fi

  success "Node.js $(node --version) instalado y VERIFICADO"
  install_pnpm
}

install_pnpm() {
  # Verificar si ya es la versión exacta
  if command -v pnpm &>/dev/null; then
    local current_pnpm
    current_pnpm=$(pnpm --version 2>/dev/null || echo "0.0.0")
    if [[ "$current_pnpm" == "$PNPM_VERSION" ]]; then
      success "pnpm ${PNPM_VERSION} — versión exacta confirmada"
      return 0
    fi
    # Versión incorrecta: eliminar
    info "pnpm ${current_pnpm} encontrado, necesitamos ${PNPM_VERSION}. Reemplazando..."
    npm uninstall -g pnpm 2>/dev/null >> "$LOG_FILE" 2>&1 || true
  fi

  npm install -g "pnpm@${PNPM_VERSION}" >> "$LOG_FILE" 2>&1

  # ── VERIFICACIÓN OBLIGATORIA ──
  local final_pnpm
  final_pnpm=$(pnpm --version 2>/dev/null || echo "FALLO")
  if [[ "$final_pnpm" != "$PNPM_VERSION" ]]; then
    fatal "pnpm se instaló como ${final_pnpm}, necesitamos ${PNPM_VERSION}. Inaceptable."
  fi
  success "pnpm ${PNPM_VERSION} instalado y VERIFICADO"
}

###############################################################################
# PASO 4: POSTGRESQL — Versión EXACTA + pgvector
###############################################################################
install_postgresql() {
  if [[ "$SKIP_DB" == true ]]; then
    step "PostgreSQL omitido (base de datos externa)"
    return 0
  fi

  step "Instalando PostgreSQL ${PG_VERSION} + pgvector (obligatorio)"

  # Verificar si ya está instalado con versión correcta
  if command -v psql &>/dev/null; then
    local pg_installed
    pg_installed=$(psql --version 2>/dev/null | grep -oP '\d+' | head -1 || echo "0")
    if [[ "$pg_installed" -eq $PG_VERSION ]]; then
      success "PostgreSQL ${PG_VERSION} — versión correcta confirmada"
      ensure_postgresql_running
      configure_postgresql
      return 0
    fi
    # Versión incorrecta: no es responsabilidad nuestra migrar datos de PG
    warn "PostgreSQL ${pg_installed} encontrado pero necesitamos ${PG_VERSION}."
    info "Instalando PostgreSQL ${PG_VERSION} en paralelo..."
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

  # ── VERIFICACIÓN OBLIGATORIA ──
  local final_pg
  final_pg=$(psql --version 2>/dev/null | grep -oP '\d+' | head -1 || echo "0")
  if [[ "$final_pg" -ne $PG_VERSION ]]; then
    fatal "PostgreSQL se instaló como v${final_pg}, necesitamos v${PG_VERSION}. Inaceptable."
  fi

  success "PostgreSQL ${PG_VERSION} + pgvector instalado y VERIFICADO"
  ensure_postgresql_running
  configure_postgresql
}

ensure_postgresql_running() {
  systemctl enable postgresql >> "$LOG_FILE" 2>&1
  systemctl start postgresql >> "$LOG_FILE" 2>&1
  local retries=0
  while ! pg_isready -q 2>/dev/null; do
    retries=$((retries + 1))
    [[ $retries -ge 30 ]] && fatal "PostgreSQL no arrancó en 30 segundos."
    sleep 1
  done
  success "PostgreSQL corriendo"
}

configure_postgresql() {
  mkdir -p "$CW_CONFIG"
  local pg_pass_file="${CW_CONFIG}/.pg_pass"

  if [[ -f "$pg_pass_file" ]]; then
    PG_PASS=$(cat "$pg_pass_file")
    info "Usando contraseña PostgreSQL existente"
  else
    PG_PASS=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)
    echo "$PG_PASS" > "$pg_pass_file"
    chmod 600 "$pg_pass_file"
    info "Contraseña PostgreSQL generada"
  fi

  local user_exists
  user_exists=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${CW_USER}'" 2>/dev/null || echo "0")
  if [[ "$user_exists" != "1" ]]; then
    sudo -u postgres psql -c "CREATE USER ${CW_USER} CREATEDB SUPERUSER PASSWORD '${PG_PASS}';" >> "$LOG_FILE" 2>&1
  else
    sudo -u postgres psql -c "ALTER USER ${CW_USER} PASSWORD '${PG_PASS}';" >> "$LOG_FILE" 2>&1
  fi

  # Asegurar template1 UTF-8
  sudo -u postgres psql <<-PGSQL >> "$LOG_FILE" 2>&1 || true
    UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'template1';
    DROP DATABASE IF EXISTS template1;
    CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = 'UNICODE';
    UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template1';
PGSQL

  success "PostgreSQL configurado"
}

###############################################################################
# PASO 5: REDIS
###############################################################################
install_redis() {
  if [[ "$SKIP_DB" == true ]]; then
    step "Redis omitido (servicio externo)"
    return 0
  fi

  step "Instalando Redis ${REDIS_MIN_VERSION}+ (obligatorio)"

  if command -v redis-server &>/dev/null; then
    local redis_major
    redis_major=$(redis-server --version | grep -oP 'v=\K\d+' || echo "0")
    if [[ "$redis_major" -ge $REDIS_MIN_VERSION ]]; then
      success "Redis $(redis-server --version | grep -oP 'v=\K[\d.]+') — versión correcta"
      ensure_redis_running
      return 0
    fi
    info "Redis v${redis_major} encontrado, necesitamos v${REDIS_MIN_VERSION}+. Actualizando..."
    apt-get purge -y redis-server redis-tools 2>/dev/null >> "$LOG_FILE" 2>&1 || true
  fi

  curl -fsSL https://packages.redis.io/gpg \
    | gpg --dearmor --yes -o /usr/share/keyrings/redis-archive-keyring.gpg >> "$LOG_FILE" 2>&1
  echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/redis.list

  apt-get update -qq >> "$LOG_FILE" 2>&1
  apt-get install -y -qq redis-server >> "$LOG_FILE" 2>&1

  # ── VERIFICACIÓN OBLIGATORIA ──
  local final_redis
  final_redis=$(redis-server --version | grep -oP 'v=\K\d+' || echo "0")
  if [[ "$final_redis" -lt $REDIS_MIN_VERSION ]]; then
    fatal "Redis se instaló como v${final_redis}, necesitamos v${REDIS_MIN_VERSION}+. Inaceptable."
  fi

  success "Redis $(redis-server --version | grep -oP 'v=\K[\d.]+') instalado y VERIFICADO"
  ensure_redis_running
}

ensure_redis_running() {
  systemctl enable redis-server.service >> "$LOG_FILE" 2>&1
  systemctl start redis-server.service >> "$LOG_FILE" 2>&1
  local retries=0
  while ! redis-cli ping 2>/dev/null | grep -q PONG; do
    retries=$((retries + 1))
    [[ $retries -ge 15 ]] && fatal "Redis no arrancó en 15 segundos."
    sleep 1
  done
  success "Redis corriendo"
}

###############################################################################
# PASO 6: RUBY — Via RVM — VERSIÓN EXACTA — Sin tolerancia
###############################################################################
install_ruby() {
  step "Instalando Ruby ${RUBY_VERSION} via RVM (obligatorio)"

  # ── CREAR USUARIO SISTEMA ──
  if ! id -u "$CW_USER" &>/dev/null; then
    adduser --disabled-password --gecos "" "$CW_USER" >> "$LOG_FILE" 2>&1
    info "Usuario ${CW_USER} creado"
  fi

  # ── CONFIRMAR QUE NO HAY RUBY DEL SISTEMA ──
  # Si /usr/bin/ruby existe y NO es de RVM, eliminarlo
  if [[ -f /usr/bin/ruby ]] || [[ -L /usr/bin/ruby ]]; then
    if ! readlink -f /usr/bin/ruby 2>/dev/null | grep -q rvm; then
      info "Eliminando /usr/bin/ruby residual (no es RVM)..."
      rm -f /usr/bin/ruby /usr/bin/ruby3* /usr/bin/erb /usr/bin/gem /usr/bin/irb /usr/bin/rdoc /usr/bin/ri
    fi
  fi

  # ── INSTALAR RVM (si no existe) ──
  if [[ ! -d "/usr/local/rvm" ]] && [[ ! -d "${CW_HOME}/.rvm" ]]; then
    info "Instalando RVM..."
    gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys \
      409B6B1796C275462A1703113804BB82D39DC0E3 \
      7D2BAF1CF37B13E2069D6956105BD0E739499BDB >> "$LOG_FILE" 2>&1 || true
    gpg2 --keyserver hkp://keyserver.ubuntu.com --recv-keys \
      409B6B1796C275462A1703113804BB82D39DC0E3 \
      7D2BAF1CF37B13E2069D6956105BD0E739499BDB >> "$LOG_FILE" 2>&1 || true
    curl -sSL https://get.rvm.io | bash -s stable >> "$LOG_FILE" 2>&1
    # Agregar usuario al grupo rvm
    usermod -aG rvm "$CW_USER" 2>/dev/null || adduser "$CW_USER" rvm >> "$LOG_FILE" 2>&1 || true
    success "RVM instalado"
  else
    success "RVM ya presente"
  fi

  # ── INSTALAR RUBY EXACTO + BUNDLER EXACTO ──
  # Ruby 3.4.4 trae Bundler 2.6.x como DEFAULT GEM (incrustado en Ruby).
  # gem uninstall NO puede eliminar default gems. Hay que borrarlos FÍSICAMENTE
  # del filesystem y luego instalar la versión que necesitamos.
  info "Instalando Ruby ${RUBY_VERSION} (esto toma varios minutos)..."
  run_as_cw "
rvm autolibs disable
rvm install 'ruby-${RUBY_VERSION}' --no-docs
rvm use 'ruby-${RUBY_VERSION}' --default
rvm cleanup all 2>/dev/null || true
" >> "$LOG_FILE" 2>&1

  # ── ELIMINAR BUNDLER DEFAULT GEM FÍSICAMENTE ──
  # Los default gems viven dentro del directorio de Ruby, no en GEM_HOME.
  # gem uninstall NO puede eliminarlos. Hay que borrar los archivos a mano.
  # Cubrimos TODAS las posibles ubicaciones de RVM (system-wide y user).
  info "Eliminando TODO rastro de Bundler (físicamente)..."

  local ruby_gem_minor="${RUBY_VERSION%.*}"  # 3.4
  local ruby_gem_dir="${ruby_gem_minor}.0"    # 3.4.0

  # Buscar en TODAS las posibles rutas de RVM
  local rvm_base_dirs=()
  [[ -d "/usr/local/rvm" ]] && rvm_base_dirs+=("/usr/local/rvm")
  [[ -d "${CW_HOME}/.rvm" ]] && rvm_base_dirs+=("${CW_HOME}/.rvm")

  for rvm_base in "${rvm_base_dirs[@]}"; do
    local rvm_ruby_dir="${rvm_base}/rubies/ruby-${RUBY_VERSION}"

    if [[ -d "$rvm_ruby_dir" ]]; then
      # A. Default gems dentro del directorio de Ruby
      rm -f "${rvm_ruby_dir}/lib/ruby/gems/${ruby_gem_dir}/specifications/default/bundler-"*.gemspec 2>/dev/null || true
      rm -rf "${rvm_ruby_dir}/lib/ruby/${ruby_gem_dir}/bundler" 2>/dev/null || true
      rm -f "${rvm_ruby_dir}/lib/ruby/${ruby_gem_dir}/bundler.rb" 2>/dev/null || true
      rm -f "${rvm_ruby_dir}/bin/bundle" "${rvm_ruby_dir}/bin/bundler" 2>/dev/null || true
      rm -f "${rvm_ruby_dir}/lib/ruby/gems/${ruby_gem_dir}/specifications/bundler-"*.gemspec 2>/dev/null || true
      rm -rf "${rvm_ruby_dir}/lib/ruby/gems/${ruby_gem_dir}/gems/bundler-"* 2>/dev/null || true
      info "  Limpiado: ${rvm_ruby_dir}"
    fi

    # B. GEM_HOME: /usr/local/rvm/gems/ruby-3.4.4/
    local gem_home="${rvm_base}/gems/ruby-${RUBY_VERSION}"
    if [[ -d "$gem_home" ]]; then
      rm -f "${gem_home}/specifications/bundler-"*.gemspec 2>/dev/null || true
      rm -f "${gem_home}/specifications/default/bundler-"*.gemspec 2>/dev/null || true
      rm -rf "${gem_home}/gems/bundler-"* 2>/dev/null || true
      rm -f "${gem_home}/bin/bundle" "${gem_home}/bin/bundler" 2>/dev/null || true
      rm -rf "${gem_home}/cache/bundler-"*.gem 2>/dev/null || true
      info "  Limpiado: ${gem_home}"
    fi

    # C. Global gemset: /usr/local/rvm/gems/ruby-3.4.4@global/
    local gem_global="${rvm_base}/gems/ruby-${RUBY_VERSION}@global"
    if [[ -d "$gem_global" ]]; then
      rm -f "${gem_global}/specifications/bundler-"*.gemspec 2>/dev/null || true
      rm -f "${gem_global}/specifications/default/bundler-"*.gemspec 2>/dev/null || true
      rm -rf "${gem_global}/gems/bundler-"* 2>/dev/null || true
      rm -f "${gem_global}/bin/bundle" "${gem_global}/bin/bundler" 2>/dev/null || true
      rm -rf "${gem_global}/cache/bundler-"*.gem 2>/dev/null || true
      info "  Limpiado: ${gem_global}"
    fi
  done

  # D. Último recurso: buscar y eliminar CUALQUIER bundler que no sea 2.5.16 en todo RVM
  for rvm_base in "${rvm_base_dirs[@]}"; do
    find "$rvm_base" -name "bundler-*.gemspec" ! -name "bundler-${BUNDLER_VERSION}.gemspec" -delete 2>/dev/null || true
    find "$rvm_base" -type d -name "bundler-*" ! -name "bundler-${BUNDLER_VERSION}" -exec rm -rf {} + 2>/dev/null || true
  done

  info "Todo rastro de Bundler eliminado"

  # ── INSTALAR BUNDLER EXACTO ──
  info "Instalando Bundler ${BUNDLER_VERSION} como ÚNICO bundler..."
  run_as_cw "
gem install bundler -v '${BUNDLER_VERSION}' --no-document --force --default
" >> "$LOG_FILE" 2>&1

  # ── VERIFICACIÓN OBLIGATORIA ──
  local installed_ruby
  installed_ruby=$(run_as_cw "ruby -v 2>&1 | grep -oP 'ruby \K[\d.]+'" 2>/dev/null || echo "FALLO")
  info "Ruby detectado: ${installed_ruby}"

  if [[ "$installed_ruby" != "${RUBY_VERSION}" ]]; then
    error "Ruby ${RUBY_VERSION} NO está activo. Se detectó: ${installed_ruby}"
    info "Diagnóstico — which ruby:"
    run_as_cw "which ruby && ruby -v && echo PATH=\$PATH" 2>&1 | tee -a "$LOG_FILE" || true
    info "Diagnóstico — RVM rubies:"
    run_as_cw "rvm list" 2>&1 | tee -a "$LOG_FILE" || true
    fatal "Ruby ${RUBY_VERSION} OBLIGATORIO no está activo. Ver ${LOG_FILE}"
  fi

  local installed_bundler
  installed_bundler=$(run_as_cw "bundle version 2>&1 | grep -oP 'Bundler version \K[\d.]+'" 2>/dev/null || echo "FALLO")
  if [[ "$installed_bundler" != "${BUNDLER_VERSION}" ]]; then
    error "Bundler detectado: ${installed_bundler} (esperado: ${BUNDLER_VERSION})"
    info "Diagnóstico — gem list bundler:"
    run_as_cw "gem list bundler && which bundle && ls -la \$(which bundle)" 2>&1 | tee -a "$LOG_FILE" || true
    fatal "Bundler ${BUNDLER_VERSION} OBLIGATORIO. Detectado: ${installed_bundler}. Ver ${LOG_FILE}"
  fi

  success "Ruby ${RUBY_VERSION} + Bundler ${BUNDLER_VERSION} — VERIFICADO"
}

###############################################################################
# PASO 7: CÓDIGO DE LA APLICACIÓN
###############################################################################
clone_or_update_repo() {
  step "Configurando código de la aplicación"

  if [[ -d "$CW_APP" ]]; then
    if [[ "$UPGRADE_MODE" == true ]]; then
      info "Actualizando repositorio..."
      run_as_cw "
cd chatwoot
git fetch origin
git checkout '${GIT_BRANCH}' 2>/dev/null || git checkout -b '${GIT_BRANCH}' 'origin/${GIT_BRANCH}'
git reset --hard 'origin/${GIT_BRANCH}'
" >> "$LOG_FILE" 2>&1
      success "Repositorio actualizado: ${GIT_BRANCH}"
    else
      success "Repositorio ya existe"
    fi
  else
    info "Clonando repositorio..."
    run_as_cw "
git clone '${GIT_REPO}' chatwoot
cd chatwoot
git checkout '${GIT_BRANCH}'
" >> "$LOG_FILE" 2>&1
    success "Repositorio clonado: ${GIT_BRANCH}"
  fi
}

###############################################################################
# PASO 8: DEPENDENCIAS DE LA APLICACIÓN
###############################################################################
install_app_dependencies() {
  step "Instalando dependencias de la aplicación"

  info "bundle install (esto toma varios minutos)..."
  run_as_cw "
cd chatwoot
bundle config set --local deployment false
bundle config set --local without 'development test'
bundle install --jobs $(nproc)
" >> "$LOG_FILE" 2>&1
  success "Gems de Ruby instalados"

  info "pnpm install..."
  run_as_cw "
cd chatwoot
pnpm install --frozen-lockfile 2>/dev/null || pnpm install
" >> "$LOG_FILE" 2>&1
  success "Paquetes JavaScript instalados"
}

###############################################################################
# PASO 9: CONFIGURACIÓN DEL ENTORNO (.env)
###############################################################################
configure_environment() {
  step "Configurando entorno"

  local env_file="${CW_APP}/.env"

  # En upgrade, preservar .env existente (solo arreglar defaults)
  if [[ "$UPGRADE_MODE" == true ]] && [[ -f "$env_file" ]]; then
    if grep -q "replace_with_lengthy_secure_hex" "$env_file" 2>/dev/null; then
      local new_secret
      new_secret=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 64)
      sed -i "s/SECRET_KEY_BASE=.*/SECRET_KEY_BASE=${new_secret}/" "$env_file"
      info "SECRET_KEY_BASE default reemplazado"
    fi
    success ".env existente preservado (modo upgrade)"
    return 0
  fi

  # Generar todos los secretos
  local secret_key encryption_pk encryption_dk encryption_salt
  secret_key=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 64)
  encryption_pk=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)
  encryption_dk=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)
  encryption_salt=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 32)

  local frontend_url="http://0.0.0.0:3000"
  [[ -n "$DOMAIN" ]] && frontend_url="https://${DOMAIN}"

  local pg_host="localhost" pg_user="${CW_USER}" pg_pass_val="${PG_PASS}" redis_url="redis://localhost:6379"
  if [[ "$SKIP_DB" == true ]]; then
    pg_host="" pg_user="" pg_pass_val="" redis_url=""
    warn "Configuración de base de datos vacía. Configura .env manualmente."
  fi

  sudo -i -u "$CW_USER" bash -c "cat > '${env_file}'" <<ENVFILE
# Chatwoot v${CHATWOOT_VERSION} — Generado $(date -Iseconds)
# Instalador v${INSTALLER_VERSION}

SECRET_KEY_BASE=${secret_key}
FRONTEND_URL=${frontend_url}
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=true
LOG_LEVEL=info
FORCE_SSL=false

ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=${encryption_pk}
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=${encryption_dk}
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=${encryption_salt}

POSTGRES_HOST=${pg_host}
POSTGRES_USERNAME=${pg_user}
POSTGRES_PASSWORD=${pg_pass_val}
RAILS_MAX_THREADS=5

REDIS_URL=${redis_url}
REDIS_PASSWORD=

MAILER_SENDER_EMAIL=Chatwoot <noreply@${DOMAIN:-localhost}>
SMTP_DOMAIN=${DOMAIN:-localhost}
SMTP_ADDRESS=
SMTP_PORT=587
SMTP_USERNAME=
SMTP_PASSWORD=
SMTP_AUTHENTICATION=login
SMTP_ENABLE_STARTTLS_AUTO=true
SMTP_OPENSSL_VERIFY_MODE=peer

ACTIVE_STORAGE_SERVICE=local
ENABLE_ACCOUNT_SIGNUP=false
ENABLE_PUSH_RELAY_SERVER=false
SIDEKIQ_CONCURRENCY=10
INSTALLATION_ENV=linux_script
ENVFILE

  chmod 600 "$env_file"
  chown "${CW_USER}:${CW_USER}" "$env_file"
  success "Entorno configurado (secretos auto-generados)"
}

###############################################################################
# PASO 10: DIRECTORIOS
###############################################################################
prepare_directories() {
  step "Preparando directorios"

  run_as_cw "
cd chatwoot
mkdir -p tmp/pids tmp/cache tmp/sockets log storage
" >> "$LOG_FILE" 2>&1

  success "Directorios creados"
}

###############################################################################
# PASO 11: COMPILAR ASSETS
###############################################################################
compile_assets() {
  step "Compilando assets (esto toma varios minutos)"

  run_as_cw "
cd chatwoot
RAILS_ENV=production \
NODE_OPTIONS='--max-old-space-size=4096' \
SECRET_KEY_BASE=precompile_placeholder \
bundle exec rake assets:precompile
" >> "$LOG_FILE" 2>&1

  success "Assets compilados"
}

###############################################################################
# PASO 12: MIGRACIONES DE BASE DE DATOS
###############################################################################
run_database_migrations() {
  if [[ "$SKIP_DB" == true ]]; then
    step "Migraciones omitidas (base de datos externa)"
    warn "Después de configurar .env, ejecuta:"
    warn "  cd ${CW_APP} && RAILS_ENV=production bundle exec rails db:chatwoot_prepare"
    return 0
  fi

  step "Ejecutando migraciones de base de datos"

  run_as_cw "
cd chatwoot
RAILS_ENV=production \
POSTGRES_STATEMENT_TIMEOUT=600s \
bundle exec rails db:chatwoot_prepare
" >> "$LOG_FILE" 2>&1

  success "Base de datos lista"
}

###############################################################################
# PASO 13: NGINX + SSL
###############################################################################
install_nginx_ssl() {
  if [[ "$SKIP_WEBSERVER" == true ]] || [[ -z "$DOMAIN" ]]; then
    step "Nginx/SSL omitido"
    return 0
  fi

  step "Instalando Nginx + SSL para ${DOMAIN}"

  apt-get install -y -qq nginx certbot python3-certbot-nginx >> "$LOG_FILE" 2>&1

  info "Obteniendo certificado SSL..."
  certbot certonly --non-interactive --agree-tos --nginx \
    -m "${LE_EMAIL}" -d "${DOMAIN}" >> "$LOG_FILE" 2>&1
  success "Certificado SSL obtenido"

  [[ -f /etc/ssl/dhparam ]] || curl -s https://ssl-config.mozilla.org/ffdhe4096.txt >> /etc/ssl/dhparam 2>/dev/null || true

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

  success "Nginx configurado con SSL para ${DOMAIN}"
}

###############################################################################
# PASO 14: SERVICIOS SYSTEMD
###############################################################################
configure_systemd() {
  step "Configurando servicios systemd"

  # Paths calculados desde RUBY_VERSION — coinciden exactamente con lo instalado por RVM
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

  if [[ -f "${CW_APP}/deployment/setup_20.04.sh" ]]; then
    cp "${CW_APP}/deployment/setup_20.04.sh" /usr/local/bin/cwctl
    chmod +x /usr/local/bin/cwctl
  fi

  systemctl daemon-reload
  systemctl enable chatwoot.target >> "$LOG_FILE" 2>&1
  systemctl start chatwoot.target >> "$LOG_FILE" 2>&1

  success "Servicios systemd configurados e iniciados"
}

###############################################################################
# VERIFICACIÓN FINAL
###############################################################################
verify_installation() {
  step "Verificación final"

  sleep 5
  local all_ok=true

  # ── VERIFICAR VERSIONES EXACTAS EN PRODUCCIÓN ──
  info "Verificando versiones en producción..."

  local prod_ruby
  prod_ruby=$(run_as_cw "ruby --version" 2>/dev/null || echo "NO ENCONTRADO")
  if echo "$prod_ruby" | grep -q "${RUBY_VERSION}"; then
    success "Ruby: ${prod_ruby}"
  else
    error "Ruby INCORRECTO: ${prod_ruby} (esperado: ${RUBY_VERSION})"
    all_ok=false
  fi

  local prod_node
  prod_node=$(node --version 2>/dev/null || echo "NO ENCONTRADO")
  local prod_node_major
  prod_node_major=$(echo "$prod_node" | cut -d'.' -f1 | tr -d 'v')
  if [[ "$prod_node_major" -eq $NODE_MAJOR ]]; then
    success "Node.js: ${prod_node}"
  else
    error "Node.js INCORRECTO: ${prod_node} (esperado: v${NODE_MAJOR}.x)"
    all_ok=false
  fi

  local prod_pnpm
  prod_pnpm=$(pnpm --version 2>/dev/null || echo "NO ENCONTRADO")
  if [[ "$prod_pnpm" == "$PNPM_VERSION" ]]; then
    success "pnpm: ${prod_pnpm}"
  else
    error "pnpm INCORRECTO: ${prod_pnpm} (esperado: ${PNPM_VERSION})"
    all_ok=false
  fi

  # ── VERIFICAR SERVICIOS ──
  if systemctl is-active --quiet chatwoot-web.1.service; then
    success "Puma web server: corriendo"
  else
    error "Puma web server: NO corriendo"
    all_ok=false
  fi

  if systemctl is-active --quiet chatwoot-worker.1.service; then
    success "Sidekiq worker: corriendo"
  else
    error "Sidekiq worker: NO corriendo"
    all_ok=false
  fi

  sleep 5
  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 http://localhost:3000 2>/dev/null || echo "000")
  if [[ "$http_code" -ge 200 ]] && [[ "$http_code" -lt 500 ]]; then
    success "HTTP: ${http_code}"
  elif [[ "$http_code" == "000" ]]; then
    warn "HTTP: sin respuesta aún (servidor arrancando)"
  else
    warn "HTTP: ${http_code}"
  fi

  if [[ "$SKIP_DB" != true ]]; then
    pg_isready -q 2>/dev/null && success "PostgreSQL: corriendo" || { error "PostgreSQL: NO corriendo"; all_ok=false; }
    redis-cli ping 2>/dev/null | grep -q PONG && success "Redis: corriendo" || { error "Redis: NO corriendo"; all_ok=false; }
  fi

  if [[ "$SKIP_WEBSERVER" != true ]] && [[ -n "$DOMAIN" ]]; then
    systemctl is-active --quiet nginx && success "Nginx: corriendo" || { error "Nginx: NO corriendo"; all_ok=false; }
  fi

  if [[ "$all_ok" != true ]]; then
    warn "Algunos servicios fallaron. Ver: ${LOG_FILE}"
  fi
}

###############################################################################
# STATUS CHECK
###############################################################################
run_status_check() {
  banner
  echo -e "${BOLD}Verificación de Salud${NC}"
  echo "------------------------------------"
  echo ""

  # shellcheck source=/dev/null
  source /etc/os-release 2>/dev/null || true
  echo -e "  ${CYAN}OS:${NC}         ${PRETTY_NAME:-desconocido}"

  local ruby_ver node_ver pnpm_ver pg_ver redis_ver cw_ver
  ruby_ver=$(run_as_cw "ruby --version" 2>/dev/null || echo "no instalado")
  node_ver=$(node --version 2>/dev/null || echo "no instalado")
  pnpm_ver=$(pnpm --version 2>/dev/null || echo "no instalado")
  pg_ver=$(psql --version 2>/dev/null || echo "no instalado")
  redis_ver=$(redis-server --version 2>/dev/null | grep -oP 'v=\K[\d.]+' || echo "no instalado")

  echo -e "  ${CYAN}Ruby:${NC}       ${ruby_ver}"
  echo -e "  ${CYAN}Node.js:${NC}    ${node_ver}"
  echo -e "  ${CYAN}pnpm:${NC}       ${pnpm_ver}"
  echo -e "  ${CYAN}PostgreSQL:${NC} ${pg_ver}"
  echo -e "  ${CYAN}Redis:${NC}      ${redis_ver}"

  if [[ -f "${CW_APP}/package.json" ]]; then
    cw_ver=$(grep '"version"' "${CW_APP}/package.json" 2>/dev/null | head -1 | grep -oP '"\K[\d.]+' || echo "desconocido")
    echo -e "  ${CYAN}Chatwoot:${NC}   ${cw_ver}"
  fi

  echo ""
  echo -e "${BOLD}Servicios${NC}"
  echo "------------------------------------"
  echo ""

  for svc in chatwoot-web.1 chatwoot-worker.1 postgresql redis-server nginx; do
    local status
    if systemctl is-active --quiet "${svc}.service" 2>/dev/null || systemctl is-active --quiet "${svc}" 2>/dev/null; then
      status="${GREEN}corriendo${NC}"
    else
      status="${RED}detenido${NC}"
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
# MENSAJE FINAL
###############################################################################
print_completion() {
  local access_url
  if [[ -n "$DOMAIN" ]]; then
    access_url="https://${DOMAIN}"
  else
    local public_ip
    public_ip=$(curl -s --max-time 5 http://checkip.amazonaws.com 2>/dev/null || echo "TU_IP")
    access_url="http://${public_ip}:3000"
  fi

  echo ""
  echo -e "${GREEN}${BOLD}+--------------------------------------------------------------+${NC}"
  echo -e "${GREEN}${BOLD}|              Instalación Completa!                            |${NC}"
  echo -e "${GREEN}${BOLD}+--------------------------------------------------------------+${NC}"
  echo ""
  echo -e "  ${BOLD}Acceso:${NC}   ${access_url}"
  echo -e "  ${BOLD}Versión:${NC}  Chatwoot v${CHATWOOT_VERSION}"
  echo -e "  ${BOLD}App:${NC}      ${CW_APP}"
  echo -e "  ${BOLD}Config:${NC}   ${CW_APP}/.env"
  echo -e "  ${BOLD}Log:${NC}      ${LOG_FILE}"
  echo ""
  echo -e "  ${BOLD}Comandos:${NC}"
  echo -e "    systemctl status chatwoot.target            # Estado"
  echo -e "    systemctl restart chatwoot.target           # Reiniciar"
  echo -e "    journalctl -u chatwoot-web.1.service -f     # Logs web"
  echo -e "    journalctl -u chatwoot-worker.1.service -f  # Logs worker"
  echo -e "    sudo bash install.sh --status               # Verificar salud"
  echo ""
}

###############################################################################
# FLUJO DE UPGRADE
###############################################################################
run_upgrade() {
  STEP_TOTAL=10

  info "Iniciando upgrade a Chatwoot v${CHATWOOT_VERSION}..."
  purge_conflicting_software
  clone_or_update_repo
  install_system_dependencies
  install_nodejs
  install_ruby
  install_app_dependencies
  prepare_directories
  compile_assets

  step "Ejecutando migraciones"
  run_as_cw "
cd chatwoot
RAILS_ENV=production \
POSTGRES_STATEMENT_TIMEOUT=600s \
bundle exec rails db:migrate
" >> "$LOG_FILE" 2>&1
  success "Migraciones completas"

  configure_systemd
  verify_installation
  print_completion
}

###############################################################################
# FLUJO DE INSTALACIÓN NUEVA
###############################################################################
run_install() {
  STEP_TOTAL=15

  purge_conflicting_software
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
  echo -e "${BOLD}Verificaciones Previas${NC}"
  echo "------------------------------------"
  check_os
  check_resources
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
