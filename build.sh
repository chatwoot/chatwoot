#!/usr/bin/env bash

set -euo pipefail

# Configurações padrão
REGISTRY="witrocha"
IMAGE_NAME="chatwit"
LATEST=true
NO_ENTERPRISE=false
DISABLE_TELEMETRY=true
NO_CACHE=false
NO_PUSH=false
NO_DEPLOY=false
STACK_NAME="chatwoot_app"
PORTAINER_ENDPOINT_ID="${PORTAINER_ENDPOINT_ID:-1}"

for envfile in .env .env.local .env.development; do
    if [ -f "${envfile}" ] && grep -qE '^PORTAINER_' "${envfile}" 2>/dev/null; then
        eval "$(grep -E '^PORTAINER_' "${envfile}" | sed 's/^/export /')"
        break
    fi
done

PORTAINER_URL="${PORTAINER_URL:-}"
PORTAINER_API_KEY="${PORTAINER_API_KEY:-}"

generate_default_tag() {
    if git rev-parse --short HEAD >/dev/null 2>&1; then
        git rev-parse --short HEAD
    else
        date +%Y%m%d%H%M%S
    fi
}

force_update_service() {
    local service_name="${STACK_NAME}_${1}"
    local image="$2"

    echo -e "\033[36m[DEPLOY] Buscando serviço ${service_name}...\033[0m"

    local services_json
    services_json=$(curl -sf -H "X-API-Key: ${PORTAINER_API_KEY}" \
        "${PORTAINER_URL}/api/endpoints/${PORTAINER_ENDPOINT_ID}/docker/services?filters=%7B%22name%22%3A%5B%22${service_name}%22%5D%7D" \
        2>/dev/null) || {
        echo -e "\033[31m[ERROR] Falha ao listar serviços no Portainer.\033[0m"
        return 1
    }

    local service_id
    service_id=$(echo "${services_json}" | jq -r --arg name "${service_name}" '.[] | select(.Spec.Name == $name) | .ID' 2>/dev/null)

    if [ -z "${service_id}" ] || [ "${service_id}" = "null" ]; then
        echo -e "\033[31m[ERROR] Serviço ${service_name} não encontrado no Swarm.\033[0m"
        return 1
    fi

    local service_detail version current_spec updated_spec http_code
    service_detail=$(curl -sf -H "X-API-Key: ${PORTAINER_API_KEY}" \
        "${PORTAINER_URL}/api/endpoints/${PORTAINER_ENDPOINT_ID}/docker/services/${service_id}" \
        2>/dev/null) || {
        echo -e "\033[31m[ERROR] Falha ao obter detalhes do serviço ${service_name}.\033[0m"
        return 1
    }

    version=$(echo "${service_detail}" | jq '.Version.Index')
    current_spec=$(echo "${service_detail}" | jq '.Spec')
    updated_spec=$(echo "${current_spec}" | jq --arg img "${image}" '.TaskTemplate.ForceUpdate = ((.TaskTemplate.ForceUpdate // 0) + 1) | .TaskTemplate.ContainerSpec.Image = $img')

    http_code=$(curl -sf -o /dev/null -w "%{http_code}" \
        -X POST \
        -H "X-API-Key: ${PORTAINER_API_KEY}" \
        -H "Content-Type: application/json" \
        "${PORTAINER_URL}/api/endpoints/${PORTAINER_ENDPOINT_ID}/docker/services/${service_id}/update?version=${version}" \
        -d "${updated_spec}" \
        2>/dev/null) || http_code="000"

    if [ "${http_code}" = "200" ]; then
        echo -e "\033[32m[SUCCESS] ${service_name} atualizado para ${image}.\033[0m"
        return 0
    fi

    echo -e "\033[31m[ERROR] Falha ao atualizar ${service_name} (HTTP ${http_code}).\033[0m"
    return 1
}

# Função de ajuda
show_help() {
    cat << EOF
Script de Build de Produção - Chatwit

USAGE:
    ./build.sh [OPTIONS]

OPTIONS:
    -v, --version VERSION     Tag da imagem (padrão: git sha curto)
    -r, --registry REGISTRY  Nome do registry (padrão: witrocha)
    -i, --image IMAGE         Nome da imagem (padrão: chatwit)
    -l, --latest              Mantém a tag 'latest' habilitada
        --no-latest           Não adiciona a tag 'latest'
    --no-enterprise           Usa Dockerfile padrão em vez do enterprise
    --enable-telemetry        Habilita telemetria (padrão: desabilitada)
    --no-cache                Build sem cache
    --no-push                 Não faz push para o registry
    --no-deploy               Não faz deploy automático no Swarm
    --stack-name NAME         Nome da stack no Swarm/Portainer (padrão: chatwit-production)
    -h, --help                Mostra esta ajuda

EXAMPLES:
    ./build.sh
    ./build.sh -v v5.0.0
    ./build.sh --no-latest --no-push
    ./build.sh --no-enterprise

DEPLOY AUTOMÁTICO:
    Defina PORTAINER_URL, PORTAINER_API_KEY e opcionalmente PORTAINER_ENDPOINT_ID
    em .env, .env.local, .env.development ou no ambiente.

EOF
}

# Processamento de argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        -i|--image)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -l|--latest)
            LATEST=true
            shift
            ;;
        --no-latest)
            LATEST=false
            shift
            ;;
        --no-enterprise)
            NO_ENTERPRISE=true
            shift
            ;;
        --enable-telemetry)
            DISABLE_TELEMETRY=false
            shift
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        --no-push)
            NO_PUSH=true
            shift
            ;;
        --no-deploy)
            NO_DEPLOY=true
            shift
            ;;
        --stack-name)
            STACK_NAME="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Opção desconhecida: $1"
            show_help
            exit 1
            ;;
    esac
done

VERSION="${VERSION:-$(generate_default_tag)}"

# Construir array de tags
TAGS=("$VERSION")
if [ "$LATEST" = true ]; then
    TAGS+=("latest")
fi

FULL_IMAGE="$REGISTRY/$IMAGE_NAME"
PRIMARY_TAG="${TAGS[0]}"
FULL_PRIMARY_IMAGE="${FULL_IMAGE}:${PRIMARY_TAG}"
CAN_DEPLOY=false

if [ "$NO_PUSH" = false ] && [ "$NO_DEPLOY" = false ] && [ -n "$PORTAINER_URL" ] && [ -n "$PORTAINER_API_KEY" ]; then
    CAN_DEPLOY=true
fi

# Definir Dockerfile
if [ "$NO_ENTERPRISE" = true ]; then
    DOCKERFILE="Dockerfile"
    echo -e "\033[36m[INFO] Usando: Dockerfile (padrão)\033[0m"
else
    DOCKERFILE="Dockerfile.enterprise"
    echo -e "\033[36m[INFO] Usando: Dockerfile.enterprise\033[0m"
fi

echo -e "\033[32m[BUILD] Building ${FULL_IMAGE} with tags: ${TAGS[*]}\033[0m"
if [ "$CAN_DEPLOY" = true ]; then
    echo -e "\033[36m[DEPLOY] Autodeploy ativo para a stack ${STACK_NAME}.\033[0m"
elif [ "$NO_DEPLOY" = true ]; then
    echo -e "\033[33m[DEPLOY] Autodeploy desabilitado via --no-deploy.\033[0m"
else
    echo -e "\033[33m[DEPLOY] Autodeploy indisponível; defina PORTAINER_URL e PORTAINER_API_KEY.\033[0m"
fi

# Preparar argumentos de build
BUILD_ARGS=()
if [ "$DISABLE_TELEMETRY" = true ]; then
    echo -e "\033[32m[PRIVACY] Desabilitando telemetria na imagem...\033[0m"
    BUILD_ARGS+=(--build-arg DISABLE_TELEMETRY=true)
    BUILD_ARGS+=(--build-arg ANALYTICS_TOKEN=)
    BUILD_ARGS+=(--build-arg CHATWOOT_HUB_URL=http://localhost:9999)
fi

echo -e "\033[33m[BUILD] Building ${FULL_IMAGE}:${PRIMARY_TAG}...\033[0m"

# Preparar comando de build
DOCKER_BUILD_CMD=(docker build -f "$DOCKERFILE")

if [ "$NO_CACHE" = true ]; then
    DOCKER_BUILD_CMD+=(--no-cache)
    echo -e "\033[33m[INFO] Build sem cache habilitado\033[0m"
fi

if [ ${#BUILD_ARGS[@]} -gt 0 ]; then
    DOCKER_BUILD_CMD+=("${BUILD_ARGS[@]}")
fi

DOCKER_BUILD_CMD+=(-t "${FULL_IMAGE}:${PRIMARY_TAG}" .)

# Executar comando de build
echo -e "\033[36m[EXEC] ${DOCKER_BUILD_CMD[*]}\033[0m"
"${DOCKER_BUILD_CMD[@]}"

# Verificar se o build foi bem-sucedido
if [ $? -eq 0 ]; then
    echo -e "\033[32m[SUCCESS] Build successful!\033[0m"
    
    # Tag com as tags adicionais
    if [ ${#TAGS[@]} -gt 1 ]; then
        for ((i=1; i<${#TAGS[@]}; i++)); do
            ADDITIONAL_TAG="${TAGS[$i]}"
            docker tag "${FULL_IMAGE}:${PRIMARY_TAG}" "${FULL_IMAGE}:${ADDITIONAL_TAG}"
            echo -e "\033[32m[TAG] Tagged as ${ADDITIONAL_TAG}\033[0m"
        done
    fi
    
    echo -e "\033[32m[COMPLETE] Imagem criada com sucesso:\033[0m"
    for tag in "${TAGS[@]}"; do
        echo -e "\033[36m  -> ${FULL_IMAGE}:${tag}\033[0m"
    done
    
    # Push para o registry
    if [ "$NO_PUSH" = false ]; then
        echo -e "\033[33m[PUSH] Iniciando push para o registro (padrão)...\033[0m"
        echo -e "\033[36m[INFO] Para desabilitar, use a flag --no-push.\033[0m"
        
        DEPLOY_IMAGE="${FULL_PRIMARY_IMAGE}"

        for tag in "${TAGS[@]}"; do
            echo -e "\033[36m[PUSH] Enviando ${FULL_IMAGE}:${tag}...\033[0m"
            if PUSH_OUT=$(docker push "${FULL_IMAGE}:${tag}" 2>&1); then
                echo "${PUSH_OUT}"

                if [ "${tag}" = "${PRIMARY_TAG}" ]; then
                    PRIMARY_DIGEST=$(echo "${PUSH_OUT}" | awk '/digest:/ {print $3; exit}')
                    if [ -n "${PRIMARY_DIGEST}" ]; then
                        DEPLOY_IMAGE="${FULL_PRIMARY_IMAGE}@${PRIMARY_DIGEST}"
                    fi
                fi
                echo -e "\033[32m[SUCCESS] Push da tag ${tag} concluído.\033[0m"
            else
                echo "${PUSH_OUT}"
                echo -e "\033[31m[ERROR] Falha no push da tag ${tag}!\033[0m"
                exit 1
            fi
        done
        
        echo -e "\033[32m[COMPLETE] Todas as tags foram enviadas para o registro.\033[0m"

        if [ "$CAN_DEPLOY" = true ]; then
            echo -e "\033[33m[DEPLOY] Aguardando 5s para propagação da imagem no registry...\033[0m"
            sleep 5

            deploy_ok=0
            deploy_fail=0

            for service in chatwoot_sidekiq chatwoot_app; do
                if force_update_service "$service" "$DEPLOY_IMAGE"; then
                    deploy_ok=$((deploy_ok + 1))
                    if [ "$service" = "chatwoot_sidekiq" ]; then
                        sleep 1
                    fi
                else
                    deploy_fail=$((deploy_fail + 1))
                fi
            done

            if [ "$deploy_fail" -eq 0 ]; then
                echo -e "\033[32m[DEPLOY] ${deploy_ok} serviço(s) atualizado(s) com sucesso.\033[0m"
            else
                echo -e "\033[31m[DEPLOY] ${deploy_ok} serviço(s) atualizados, ${deploy_fail} falha(s).\033[0m"
                exit 1
            fi
        fi
    else
        echo -e "\033[33m[INFO] Push automático desabilitado pela flag --no-push.\033[0m"
        echo -e "\033[33m[INFO] Para fazer push manualmente:\033[0m"
        for tag in "${TAGS[@]}"; do
            echo -e "\033[37m  docker push ${FULL_IMAGE}:${tag}\033[0m"
        done
    fi
    
    if [ "$DISABLE_TELEMETRY" = true ]; then
        echo ""
        echo -e "\033[32m[PRIVACY] TELEMETRIA DESABILITADA NA IMAGEM!\033[0m"
    fi
    
else
    echo -e "\033[31m[ERROR] Build failed!\033[0m"
    exit 1
fi
