#!/bin/bash

# Script de instalación y administración de Chatwoot
# ===================================================
#
# CONFIGURACIÓN IMPORTANTE:
# ------------------------
# Antes de usar este script, configura la variable CHATWOOT_HOST_IP según tu entorno:
#
# Para acceso local:
#   export CHATWOOT_HOST_IP=127.0.0.1
#
# Para acceso desde la red:
#   export CHATWOOT_HOST_IP=tu_ip_del_servidor
#   Ejemplo: export CHATWOOT_HOST_IP=10.254.0.4
#
# O agrégala a tu ~/.bashrc para que sea permanente:
#   echo 'export CHATWOOT_HOST_IP=tu_ip_aqui' >> ~/.bashrc

CHATWOOT_REPO="https://github.com/sau64inc/chatwoot.git"
CHATWOOT_VERSION="v4.6.0"
DOCKER_COMPOSE_SRC="docker-compose.yaml"
DOCKER_COMPOSE_DST="docker-compose-managernow.yaml"
POSTGRES_PASSWORD="managernow_postgres_2024"
ENV_FILE=".env"
ENV_EXAMPLE_FILE=".env.example"

# Branch a actualizar por defecto
DEFAULT_UPDATE_BRANCH="develop"

# Variable de host IP para Docker Compose (debe configurarse externamente)
CHATWOOT_HOST_IP=${CHATWOOT_HOST_IP:-0.0.0.0}

# Directorio de instalación
if [ "$1" = "install" ] && [ -n "$2" ]; then
    CHATWOOT_DIR="$2"
else
    CHATWOOT_DIR=$(dirname "$(realpath "$0")")
fi

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes con colores
print_status() {
    echo -n -e "${BLUE}[INFO]${NC} $1"
}

print_status_ok() {
    echo -e " ${GREEN}OK!${NC}"
}

print_success() {
    echo -e " ${GREEN}OK!${NC}"
}

print_warning() {
    echo
    echo -e " ${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo
    echo -e " ${RED}[ERROR]${NC} $1"
}

error_exit() {
    print_error "$1"
    print_error "Instalación cancelada"
    exit 1
}

function help() {
    echo "Uso: ./chatwoot.sh [COMANDO] [DIRECTORIO]"
    echo ""
    echo "Comandos:"
    echo ""
    echo "  install [DIR] Instalación completa en directorio especificado (por defecto: directorio actual)"
    echo "  clone        Solo descargar Chatwoot del repositorio"
    echo "  build        Generar imágenes de Docker"
    echo "  init-env     Configura archivo $ENV_FILE"
    echo "  init-dc      Configura archivo $DOCKER_COMPOSE_DST"
    echo "  init-db      Inicializa la base de datos (PostgreSQL + migraciones)"
    echo "  start        Iniciar todos los servicios de Chatwoot"
    echo "  stop         Detener todos los servicios de Chatwoot"
    echo "  console      Acceso a la consola interactiva de Rails"
    echo "  update [BR]  Actualiza código al branch (por defecto: $DEFAULT_UPDATE_BRANCH), aplica bin/update y reinicia servicios"
    echo "  sync-branch [BASE]  Rebasea la rama actual con BASE (por defecto: $DEFAULT_UPDATE_BRANCH), luego aplica bin/update sin rebuild"
    echo "  destroy      Detiene y elimina los volúmenes de Docker"
    echo "  help         Ayuda"
    echo ""
}

function check_chatwoot_exists() {
    if ! chatwoot_dir_exists; then
        echo "Error: Chatwoot no encontrado. Ejecuta './chatwoot.sh install' primero."
        exit 1
    fi
}

function chatwoot_dir_exists() {
    [ -f "$CHATWOOT_DIR/$DOCKER_COMPOSE_DST" ]
}

function change_chatwoot_dir() {
    cd "$CHATWOOT_DIR"
}

function validate_docker_compose_dst_exists() {
    if [ ! -f "$DOCKER_COMPOSE_DST" ]; then
        print_error "Archivo $DOCKER_COMPOSE_DST no existe."
        return 1
    fi

    return 0
}

function handle_existing_directory() {
    if chatwoot_dir_exists; then
        local full_path=$(pwd)/$CHATWOOT_DIR
        print_warning "El directorio ya existe: $full_path"
        echo
        echo -n -e " ${BLUE}¿Deseas eliminarlo para continuar con la instalación? (s/N): ${NC}"
        read -r confirmation
        echo

        if [[ "$confirmation" =~ ^[SsYy]$ ]]; then
            print_status "Eliminando directorio existente"
            rm -rf "$CHATWOOT_DIR"
            print_status_ok
        else
            echo
            echo -e "${BLUE}ℹ️  Instalación cancelada${NC}"
            echo
            exit 0
        fi
    fi
}

function setup_env_file() {
    if [ ! -f "$ENV_FILE" ]; then
        if [ -f "$ENV_EXAMPLE_FILE" ]; then
            echo "Archivo $ENV_FILE no encontrado. Copiando desde $ENV_EXAMPLE_FILE..."
            cp "$ENV_EXAMPLE_FILE" "$ENV_FILE"
            echo "Archivo $ENV_FILE creado."
        else
            echo "Advertencia: No se encontró $ENV_EXAMPLE_FILE."
        fi
    else
        echo "Archivo $ENV_FILE ya existe."
    fi
}

sedi() {
  if sed --version >/dev/null 2>&1; then
    sed -E -i -e "$1" "${@:2}"          # GNU
  else
    sed -E -i '' -e "$1" "${@:2}"       # macOS/BSD
  fi
}

function set_env_variable() {
    local file="$1"
    local variable="$2"
    local value="$3"

    if [ ! -f "$file" ]; then
        echo "Error: Archivo $file no encontrado."
        return 1
    fi

    if ! grep -q "^$variable=" "$file" || grep -q "^$variable=$" "$file" || grep -q "^$variable=\s*$" "$file"; then
        echo "Configurando $variable..."
        if grep -q "^$variable" "$file"; then
            sedi "s/^$variable=.*/$variable=$value/" "$file"
        else
            echo "$variable=$value" >> "$file"
        fi
        echo "$variable configurado."
    else
        echo "$variable ya está configurado."
    fi
}

function configure_env_postgres_password() {
    set_env_variable "$ENV_FILE" "POSTGRES_PASSWORD" "$POSTGRES_PASSWORD"
}

function configure_env_redis_password() {
    local redis_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    set_env_variable "$ENV_FILE" "REDIS_PASSWORD" "$redis_password"
}

function configure_env_secret_key_base() {
    local secret_key=$(openssl rand -hex 64)
    set_env_variable "$ENV_FILE" "SECRET_KEY_BASE" "$secret_key"
}

function check_services_running() {
    if [ ! -f "$DOCKER_COMPOSE_DST" ]; then
        return 1
    fi

    # Verificar si hay servicios corriendo para este docker-compose
    docker compose -f "$DOCKER_COMPOSE_DST" ps --services --filter "status=running" 2>/dev/null | grep -q .
}

function configure_docker_compose_postgres() {
    validate_docker_compose_dst_exists || return 1

    print_status "Configurando contraseña de PostgreSQL"

    sedi "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$POSTGRES_PASSWORD/" "$DOCKER_COMPOSE_DST"
    print_status_ok
}

function configure_docker_compose_ports() {
    validate_docker_compose_dst_exists || return 1

    print_status "Configurando puertos con variable de host IP"

	sedi 's/^([[:space:]]*-[[:space:]]*)["'\'']?(3000:3000)["'\'']?[[:space:]]*$/\1"${CHATWOOT_HOST_IP:-127.0.0.1}:\2"/' "$DOCKER_COMPOSE_DST"
	sedi 's/^([[:space:]]*-[[:space:]]*)["'\'']?(1025:1025)["'\'']?[[:space:]]*$/\1"${CHATWOOT_HOST_IP:-127.0.0.1}:\2"/' "$DOCKER_COMPOSE_DST"
	sedi 's/^([[:space:]]*-[[:space:]]*)["'\'']?(3036:3036)["'\'']?[[:space:]]*$/\1"${CHATWOOT_HOST_IP:-127.0.0.1}:\2"/' "$DOCKER_COMPOSE_DST"
	sedi 's/^([[:space:]]*-[[:space:]]*)["'\'']?(5432:5432)["'\'']?[[:space:]]*$/\1"${CHATWOOT_HOST_IP:-127.0.0.1}:\2"/' "$DOCKER_COMPOSE_DST"
	sedi 's/^([[:space:]]*-[[:space:]]*)["'\'']?(6379:6379)["'\'']?[[:space:]]*$/\1"${CHATWOOT_HOST_IP:-127.0.0.1}:\2"/' "$DOCKER_COMPOSE_DST"
	sedi 's/^([[:space:]]*-[[:space:]]*)["'\'']?(8025:8025)["'\'']?[[:space:]]*$/\1"${CHATWOOT_HOST_IP:-127.0.0.1}:\2"/' "$DOCKER_COMPOSE_DST"

    print_status_ok
}

function configure_docker_compose_pv() {
    validate_docker_compose_dst_exists || return 1

    print_status "Configurando aplicaciones para usar volúmenes persistentes"

    # Corregir ruta de montaje de PostgreSQL
    sedi 's|postgres:/data/postgres|postgres:/var/lib/postgresql/data|' "$DOCKER_COMPOSE_DST"

    # Corregir ruta de montaje de Redis
    sedi 's|redis:/data/redis|redis:/data|' "$DOCKER_COMPOSE_DST"

    print_status_ok
}

function init_docker_compose() {
    change_chatwoot_dir

#    if [ ! -f "$DOCKER_COMPOSE_SRC" ]; then
#        print_error "$DOCKER_COMPOSE_SRC no encontrado"
#        return 1
#    fi

#    print_status "Configurando archivo docker-compose"
#    cp "$DOCKER_COMPOSE_SRC" "$DOCKER_COMPOSE_DST"
#    print_status_ok

    # Configurar contraseña de PostgreSQL
    configure_docker_compose_postgres

    # Configurar puertos con variable de host IP
    configure_docker_compose_ports

    # Corregir rutas de volúmenes persistentes
    configure_docker_compose_pv
}

function wait_for_postgres() {
    local timeout=60
    local elapsed=0

    print_status "Esperando que PostgreSQL se inicialice"

    while [ $elapsed -lt $timeout ]; do
        if docker compose -f "$DOCKER_COMPOSE_DST" exec postgres pg_isready -U postgres >/dev/null 2>&1; then
            print_status_ok
            return 0
        fi

        echo -n "."
        sleep 2
        elapsed=$((elapsed + 2))
    done

    echo
    print_error "PostgreSQL no respondió en $timeout segundos"
    return 1
}

function wait_for_rails() {
    local timeout=120
    local elapsed=0

    print_status "Esperando que Rails se inicialice"

    while [ $elapsed -lt $timeout ]; do
        if curl -s http://"$CHATWOOT_HOST_IP":3000 >/dev/null 2>&1; then
            print_status_ok
            return 0
        fi

        echo -n "."
        sleep 3
        elapsed=$((elapsed + 3))
    done

    echo
    print_error "Rails no respondió en $timeout segundos"
    return 1
}

function clone() {
    handle_existing_directory

    print_status "Clonando repositorio de Chatwoot..."
    git clone "$CHATWOOT_REPO" "$CHATWOOT_DIR" >/dev/null 2>&1

    if [ $? -ne 0 ]; then
        print_error "Falló la clonación del repositorio"
        exit 1
    fi
    print_status_ok

    print_status "Cambiando a la versión $CHATWOOT_VERSION"
    cd "$CHATWOOT_DIR"
    git checkout "$CHATWOOT_VERSION" >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        print_status_ok
    else
        echo
        print_warning "No se pudo cambiar a la versión $CHATWOOT_VERSION"
    fi

    echo
    echo -e "${GREEN} Clonacion completada correctamente! ${NC}"
}

function build() {
    change_chatwoot_dir
    check_chatwoot_exists

    if [ ! -f "$DOCKER_COMPOSE_DST" ]; then
        print_error "$DOCKER_COMPOSE_DST no encontrado. Ejecuta 'clone' primero."
        exit 1
    fi

    print_status "Creando imagen base de Docker..."
#     docker compose -f "$DOCKER_COMPOSE_DST" build base >/dev/null 2>&1
	docker compose -f "$DOCKER_COMPOSE_DST" build base

    if [ $? -eq 0 ]; then
        print_status_ok
    else
        print_error "No se pudo crear la imagen base."
        exit 1
    fi

    print_status "Creando imágenes del server y el worker..."
    docker compose -f "$DOCKER_COMPOSE_DST" build >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        print_status_ok
    else
        print_error "No se pudo crear las imágenes del server y del worker."
        exit 1
    fi

    if [ "$CHATWOOT_DIR" != "." ]; then
        cd ..
    fi

    echo
    echo -e "${GREEN} Imágenes construidas exitosamente! ${NC}"
}

function install() {
    echo -e "${BLUE}=== INSTALACIÓN DE CHATWOOT EN DIRECTORIO: $CHATWOOT_DIR ===${NC}"

    # Verificar si necesita clonar o si ya está en el directorio del script
    if [ -n "$2" ]; then
        # Paso 1: Clone
        echo
        echo -e "${BLUE} Paso 1/5: Descargando Chatwoot${NC}"
        echo
        clone
    else
        # Omitir clonación cuando se instala en directorio del script
        echo
        echo -e "${YELLOW} Paso 1/5: Omitiendo clonación (ya en directorio de Chatwoot)${NC}"
        change_chatwoot_dir
    fi

    echo
    # Paso 2: Configuracion de $DOCKER_COMPOSE_DST
    echo -e "${BLUE} Paso 2/5: Configurando Docker Compose${NC}"
    echo
    init_docker_compose

    echo
    # Paso 3: Configuracion de $ENV_FILE
    echo -e "${BLUE} Paso 3/5: Configurando archivos${NC}"
    echo
    init_env

    echo
    # Paso 4: Build
    echo -e "${BLUE} Paso 4/5: Construyendo imágenes${NC}"
    echo
    build

    echo
    # Paso 5: Inicializacion de base de datos
    echo -e "${BLUE} Paso 5/5: Inicializando base de datos${NC}"
    echo
    init_database

    echo
    echo -e "${GREEN}🎉 INSTALACIÓN COMPLETA ${NC}"
    echo
    echo -e "${YELLOW} Para iniciar Chatwoot ejecuta:${NC}"
    echo
    echo -e "${BLUE} ./chatwoot.sh start${NC}"
    echo
    echo -n -e "${BLUE} ¿Deseas iniciarlo ahora? (s/N): ${NC}"
    read -r confirmation
    echo

    if [[ "$confirmation" =~ ^[SsYy]$ ]]; then
        echo
        echo -e "${BLUE} Iniciando Chatwoot...${NC}"
        echo
        start
    fi
}

# Nueva función: actualizar código e infraestructura
function update() {
    check_chatwoot_exists
    change_chatwoot_dir

    local target_branch="${1:-$DEFAULT_UPDATE_BRANCH}"

    if [ ! -f "$DOCKER_COMPOSE_DST" ]; then
        print_error "$DOCKER_COMPOSE_DST no encontrado. Ejecuta 'init-dc' primero."
        exit 1
    fi

    if ! check_git_repo; then
        exit 1
    fi

    prompt_continue_on_dirty_tree

    print_status "Descargando últimos cambios de git"
    git fetch --all --prune >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        print_error "git fetch falló"
        exit 1
    fi
    print_status_ok

    print_status "Cambiando a branch ${target_branch}"
    # Crear tracking si no existe
    if ! git rev-parse --verify "$target_branch" >/dev/null 2>&1; then
        git checkout -b "$target_branch" "origin/$target_branch" >/dev/null 2>&1
    else
        git checkout "$target_branch" >/dev/null 2>&1
    fi
    if [ $? -ne 0 ]; then
        print_error "No se pudo cambiar al branch $target_branch"
        exit 1
    fi
    print_status_ok

    print_status "Actualizando branch ${target_branch} (rebase)"
    if ! git pull --rebase --autostash origin "$target_branch" >/dev/null 2>&1; then
        echo
        print_warning "git pull con rebase falló; mostrando diagnóstico básico"
        git status -sb || true
        git rebase --abort >/dev/null 2>&1 || true
        print_error "git pull --rebase --autostash falló. Si tienes cambios sin confirmar, guárdalos (git add/commit) o usa: git stash -u"
        exit 1
    fi
    print_status_ok

    # Reaplicar configuración de docker-compose (idempotente)
    echo
    echo -e "${BLUE} Ajustando configuración de Docker Compose${NC}"
    init_docker_compose

    echo
    # Importante: NO reconstruimos imágenes en modo desarrollo
    print_status "Iniciando/asegurando servicios (sin rebuild)"
    if ! check_services_running; then
        docker compose -f "$DOCKER_COMPOSE_DST" up -d >/dev/null 2>&1 || true
    fi
    print_status_ok

    echo
    print_status "Ejecutando actualización (bin/update) dentro del contenedor"
    if check_services_running; then
        # Usamos exec si los servicios ya están arriba
        if ! docker compose -f "$DOCKER_COMPOSE_DST" exec rails bin/update >/dev/null 2>&1; then
            print_warning "exec bin/update falló, intentando con run --rm"
            if ! docker compose -f "$DOCKER_COMPOSE_DST" run --rm rails bin/update >/dev/null 2>&1; then
                print_error "bin/update falló"
                echo -e "${YELLOW}Sugerencia:${NC} Si el fallo persiste, intenta reiniciar servicios o, como última opción, reconstruir imágenes."
                exit 1
            fi
        fi
    else
        # Si aún no corren, ejecutar con run
        if ! docker compose -f "$DOCKER_COMPOSE_DST" run --rm rails bin/update >/dev/null 2>&1; then
            print_error "bin/update falló"
            exit 1
        fi
    fi
    print_status_ok

    echo
    print_status "Reiniciando servicios (rails, sidekiq, vite)"
    docker compose -f "$DOCKER_COMPOSE_DST" exec rails bin/rails restart >/dev/null 2>&1 || true
    docker compose -f "$DOCKER_COMPOSE_DST" restart sidekiq >/dev/null 2>&1 || true
    docker compose -f "$DOCKER_COMPOSE_DST" restart vite >/dev/null 2>&1 || true
    print_status_ok

    # Asegurar que todo siga arriba
    docker compose -f "$DOCKER_COMPOSE_DST" up -d >/dev/null 2>&1 || true

    if ! wait_for_postgres; then
        exit 1
    fi
    if ! wait_for_rails; then
        exit 1
    fi

    echo
    echo -e "${GREEN} Actualización completada correctamente.${NC}"
    echo
    echo "Versión actual:" $(git rev-parse --short HEAD) "en" $(get_current_branch)
}

function init_env() {
    check_chatwoot_exists
    change_chatwoot_dir

    print_status "Configurando $ENV_FILE"
    setup_env_file >/dev/null 2>&1
    print_status_ok

    print_status "Configurando $ENV_FILE (password de PostgreSQL)"
    configure_env_postgres_password >/dev/null 2>&1
    print_status_ok

    print_status "Configurando $ENV_FILE (password de Redis)"
    configure_env_redis_password >/dev/null 2>&1
    print_status_ok

    print_status "Configurando $ENV_FILE (SECRET_KEY_BASE con randmon value)"
    configure_env_secret_key_base >/dev/null 2>&1
    print_status_ok

}

function init_database() {
    check_chatwoot_exists
    change_chatwoot_dir

    if [ ! -f "$DOCKER_COMPOSE_DST" ]; then
        print_error "$DOCKER_COMPOSE_DST no encontrado. Ejecuta 'init-config' primero."
        exit 1
    fi

    print_status "Iniciando servicio de PostgreSQL..."
    docker compose -f "$DOCKER_COMPOSE_DST" up -d postgres >/dev/null 2>&1
    print_status_ok

    if ! wait_for_postgres; then
        exit 1
    fi


    print_status "Creando base de datos para chatwoot..."
    docker compose -f "$DOCKER_COMPOSE_DST" run --rm rails bin/rails db:create >/dev/null 2>&1

    if [ $? -eq 0 ]; then
        print_status_ok
    else
        print_error "Falló la creación de la base de datos"
        exit 1
    fi

    print_status "Ejecutando scripts de migracion e inicializacion..."
    docker compose -f "$DOCKER_COMPOSE_DST" run --rm rails bundle exec rails db:chatwoot_prepare #>/dev/null 2>&1

    if [ $? -eq 0 ]; then
        print_status_ok
    else
        print_error "Falló la inicialización de la base de datos"
        exit 1
    fi

}

function start() {
    check_chatwoot_exists
    change_chatwoot_dir

    if [ -f "$DOCKER_COMPOSE_DST" ]; then
        docker compose -f "$DOCKER_COMPOSE_DST" up -d >/dev/null 2>&1

        if ! wait_for_postgres; then
            exit 1
        fi

        if ! wait_for_rails; then
            exit 1
        fi

        echo ""
        echo "Links:"
        echo "  - Aplicación web: http://$CHATWOOT_HOST_IP:3000"
        echo "  - Monitoreo Sidekiq: http://$CHATWOOT_HOST_IP:3000/monitoring/sidekiq"
        echo "  - MailHog (Email testing): http://$CHATWOOT_HOST_IP:8025/"
        echo ""
        echo "Credenciales de desarrollo:"
        echo "  - Usuario: john@acme.inc"
        echo "  - Contraseña: Password1!"
        echo ""
        echo "Comandos útiles:"
        echo "  - Ver logs de Rails: docker compose -f $DOCKER_COMPOSE_DST logs -f rails"
        echo "  - Ver todos los logs: docker compose -f $DOCKER_COMPOSE_DST logs -f"
        echo ""
    else
        echo "Error: No se puede determinar cómo iniciar Chatwoot"
        exit 1
    fi

}

function stop() {
    check_chatwoot_exists
    change_chatwoot_dir

    if [ ! -f "$DOCKER_COMPOSE_DST" ]; then
        print_error "$DOCKER_COMPOSE_DST no encontrado."
        exit 1
    fi

    print_status "Deteniendo servicios de Chatwoot"
    docker compose -f "$DOCKER_COMPOSE_DST" down >/dev/null 2>&1
    print_status_ok

}

function console() {
    check_chatwoot_exists
    change_chatwoot_dir

    if [ ! -f "$DOCKER_COMPOSE_DST" ]; then
        print_error "$DOCKER_COMPOSE_DST no encontrado."
        exit 1
    fi

    echo -e "${BLUE}Abriendo consola interactiva de Rails...${NC}"
    echo -e "${YELLOW}Tip: Usa 'exit' para salir de la consola${NC}"
    echo

    docker compose -f "$DOCKER_COMPOSE_DST" exec rails bundle exec rails console

}

function destroy() {
    echo
    echo -e "${RED} ADVERTENCIA ${NC}"
    echo
    echo -e "${YELLOW} Se eliminarán TODOS los volúmenes de Docker, esto hace que se pierda la informacion guardada en la base de datos!${NC}"
    echo
    echo -n -e "${BLUE} ¿Estás completamente seguro? (s/N): ${NC}"
    read -r confirmation
    echo

    if [[ "$confirmation" =~ ^[SsYy]$ ]]; then
        check_chatwoot_exists
        change_chatwoot_dir

        # Verificar si hay servicios corriendo y detenerlos
        if check_services_running; then
            docker compose -f "$DOCKER_COMPOSE_DST" down >/dev/null 2>&1
        fi

        docker compose -f "$DOCKER_COMPOSE_DST" down -v >/dev/null 2>&1

        echo -e "${GREEN} Se eliminaron correctamente. ${NC}"
        echo

        cd ..
    else
        echo -e "${BLUE} Cancelado. ${NC}"
        echo
    fi
}

# Sincroniza la rama actual con develop sin reconstruir imágenes
sync_branch() {
  change_chatwoot_dir
  if ! check_git_repo; then
    return 1
  fi

  local base_branch="${1:-$DEFAULT_UPDATE_BRANCH}"

  # Verificar rama actual
  local current_branch
  current_branch=$(get_current_branch)
  if [ -z "$current_branch" ]; then
    print_error "No se pudo determinar la rama actual"
    return 1
  fi

  if [ "$current_branch" = "$base_branch" ]; then
    print_error "Estás en '$base_branch'. Ejecuta sync-branch desde otra rama para traer $base_branch al branch actual."
    return 1
  fi

  echo
  print_status "Actualizando referencias remotas"
  git fetch --all --prune >/dev/null 2>&1 || { print_error "git fetch falló"; return 1; }
  print_status_ok

  echo
  print_status "Rebasando '$current_branch' sobre 'origin/$base_branch' (autostash)"
  if ! git rebase --autostash "origin/$base_branch" >/dev/null 2>&1; then
    echo
    print_warning "Rebase falló. Puede haber conflictos."
    git status -sb || true
    echo
    echo "Sugerencias:"
    echo " - Resolver conflictos, luego: git rebase --continue"
    echo " - O abortar: git rebase --abort"
    return 1
  fi
  print_status_ok

  # Aplicar actualizaciones de deps y DB sin reconstruir imágenes
  echo
  if [ -f "$DOCKER_COMPOSE_DST" ]; then
    print_status "Asegurando servicios arriba (sin rebuild)"
    if ! check_services_running; then
      docker compose -f "$DOCKER_COMPOSE_DST" up -d >/dev/null 2>&1 || true
    fi
    print_status_ok

    print_status "Aplicando bin/update dentro del contenedor (sin rebuild)"
    if check_services_running; then
      if ! docker compose -f "$DOCKER_COMPOSE_DST" exec rails bin/update >/dev/null 2>&1; then
        print_warning "exec bin/update falló, intentando con run --rm"
        if ! docker compose -f "$DOCKER_COMPOSE_DST" run --rm rails bin/update >/dev/null 2>&1; then
          print_error "bin/update falló dentro del contenedor"
          echo "Puedes intentar: docker compose -f $DOCKER_COMPOSE_DST exec rails bin/rails db:migrate"
          return 1
        fi
      fi
    else
      if ! docker compose -f "$DOCKER_COMPOSE_DST" run --rm rails bin/update >/dev/null 2>&1; then
        print_error "bin/update falló dentro del contenedor"
        return 1
      fi
    fi
    print_status_ok

    # Reinicios suaves/duros según servicio
    print_status "Reiniciando servicios (rails, sidekiq, vite)"
    docker compose -f "$DOCKER_COMPOSE_DST" exec rails bin/rails restart >/dev/null 2>&1 || true
    docker compose -f "$DOCKER_COMPOSE_DST" restart sidekiq >/dev/null 2>&1 || true
    docker compose -f "$DOCKER_COMPOSE_DST" restart vite >/dev/null 2>&1 || true
    print_status_ok

    # Salud
    if ! wait_for_postgres; then
      return 1
    fi
    if ! wait_for_rails; then
      return 1
    fi
  else
    print_status "Aplicando bin/update en host (modo dev)"
    if ! bin/update >/dev/null 2>&1; then
      print_error "bin/update falló en host"
      return 1
    fi
    print_status_ok
  fi

  echo
  echo -e "${GREEN} Sync con '$base_branch' completado en '${current_branch}'.${NC}"
}

# Utilidades git
check_git_repo() {
    if [ ! -d .git ]; then
        print_error "No es un repositorio git."
        return 1
    fi
    return 0
}

has_uncommitted_changes() {
    if ! check_git_repo; then
        return 1
    fi
    if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
        return 0
    fi
    return 1
}

get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

prompt_continue_on_dirty_tree() {
    if has_uncommitted_changes; then
        echo
        print_warning "Tienes cambios sin confirmar en el repositorio. Podrían perderse al actualizar."
        echo -n -e " ${BLUE}¿Deseas continuar de todas formas? (s/N): ${NC}"
        read -r ans
        echo
        if [[ ! "$ans" =~ ^[SsYy]$ ]]; then
            echo -e "${BLUE} Operación cancelada.${NC}"
            exit 0
        fi
    fi
}

case "$1" in
    install)
        install "$1" "$2"
        ;;
    clone)
        clone
        ;;
    build)
        build
        ;;
    init-env)
        init_env
        ;;
    init-dc)
        init_docker_compose
        ;;
    init-db)
        init_database
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    console)
        console
        ;;
    update)
        # Permite ./chatwoot.sh update [branch]
        update "$2"
        ;;
    sync-branch)
        # Permite ./chatwoot.sh sync-branch [base-branch]
        sync_branch "$2"
        ;;
    destroy)
        destroy
        ;;
    help|--help|-h)
        help
        ;;
    "")
        help
        ;;
    *)
        echo "Error: Comando desconocido '$1'"
        help
        exit 1
        ;;
esac
