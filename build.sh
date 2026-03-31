#!/usr/bin/env bash

set -euo pipefail

# Configurações padrão
REGISTRY="witrocha"
IMAGE_NAME="chatwit"
EVOLUTION_IMAGE="${EVOLUTION_IMAGE:-witrocha/evolution-go}"
EVOLUTION_CONTEXT="${EVOLUTION_CONTEXT:-./evolution-go}"
EVOLUTION_PATCH_SCRIPT="${EVOLUTION_PATCH_SCRIPT:-./scripts/evolution-go/apply-chatwit-patches.sh}"
LATEST=true
BUILD_EVOLUTION=true
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

normalize_image_repo() {
    local image="$1"
    local image_without_digest="${image%@*}"

    if [[ "${image_without_digest##*/}" == *:* ]]; then
        echo "${image_without_digest%:*}"
    else
        echo "${image_without_digest}"
    fi
}

build_image_with_tags() {
    local full_image="$1"
    local dockerfile="$2"
    local context="$3"
    shift 3

    local docker_build_cmd=(docker build -f "$dockerfile")

    if [ "$NO_CACHE" = true ]; then
        docker_build_cmd+=(--no-cache)
    fi

    if [ $# -gt 0 ]; then
        docker_build_cmd+=("$@")
    fi

    docker_build_cmd+=(-t "${full_image}:${PRIMARY_TAG}" "$context")

    echo -e "\033[33m[BUILD] Building ${full_image}:${PRIMARY_TAG}...\033[0m"
    echo -e "\033[36m[EXEC] ${docker_build_cmd[*]}\033[0m"
    "${docker_build_cmd[@]}"

    if [ ${#TAGS[@]} -gt 1 ]; then
        for ((i=1; i<${#TAGS[@]}; i++)); do
            local additional_tag="${TAGS[$i]}"
            docker tag "${full_image}:${PRIMARY_TAG}" "${full_image}:${additional_tag}"
            echo -e "\033[32m[TAG] ${full_image}:${additional_tag}\033[0m"
        done
    fi
}

PUSHED_DEPLOY_IMAGE=""
push_image_tags() {
    local full_image="$1"
    local deploy_image="${full_image}:${PRIMARY_TAG}"
    local push_out
    local primary_digest

    for tag in "${TAGS[@]}"; do
        echo -e "\033[36m[PUSH] Enviando ${full_image}:${tag}...\033[0m"
        if push_out=$(docker push "${full_image}:${tag}" 2>&1); then
            echo "${push_out}"

            if [ "${tag}" = "${PRIMARY_TAG}" ]; then
                primary_digest=$(echo "${push_out}" | awk '/digest:/ {print $3; exit}')
                if [ -n "${primary_digest}" ]; then
                    deploy_image="${full_image}:${PRIMARY_TAG}@${primary_digest}"
                fi
            fi
            echo -e "\033[32m[SUCCESS] Push da tag ${tag} concluído.\033[0m"
        else
            echo "${push_out}"
            echo -e "\033[31m[ERROR] Falha no push da tag ${tag}!\033[0m"
            exit 1
        fi
    done

    PUSHED_DEPLOY_IMAGE="${deploy_image}"
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
        --evolution-image REPO  Repositório da imagem Evolution Go (padrão: witrocha/evolution-go)
        --evolution-context PATH Contexto do build do Evolution Go (padrão: ./evolution-go)
    -l, --latest              Mantém a tag 'latest' habilitada
        --no-latest           Não adiciona a tag 'latest'
        --skip-evolution      Não builda/pusha/deploya a imagem Evolution Go
    --no-enterprise           Usa Dockerfile padrão em vez do enterprise
    --enable-telemetry        Habilita telemetria (padrão: desabilitada)
    --no-cache                Build sem cache
    --no-push                 Não faz push para o registry
    --no-deploy               Não faz deploy automático no Swarm
    --stack-name NAME         Nome da stack no Swarm/Portainer (padrão: chatwoot_app)
    -h, --help                Mostra esta ajuda

EXAMPLES:
    ./build.sh
    ./build.sh -v v5.0.0
    ./build.sh --no-latest --no-push
    ./build.sh --no-enterprise
    ./build.sh --skip-evolution

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
        --evolution-image)
            EVOLUTION_IMAGE="$2"
            shift 2
            ;;
        --evolution-context)
            EVOLUTION_CONTEXT="$2"
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
        --skip-evolution)
            BUILD_EVOLUTION=false
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
EVOLUTION_IMAGE="$(normalize_image_repo "$EVOLUTION_IMAGE")"

# Construir array de tags
TAGS=("$VERSION")
if [ "$LATEST" = true ]; then
    TAGS+=("latest")
fi

FULL_IMAGE="$REGISTRY/$IMAGE_NAME"
PRIMARY_TAG="${TAGS[0]}"
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

if [ "$BUILD_EVOLUTION" = true ] && [ ! -f "${EVOLUTION_CONTEXT}/Dockerfile" ]; then
    echo -e "\033[31m[ERROR] Evolution Go não encontrado em ${EVOLUTION_CONTEXT}.\033[0m"
    echo -e "\033[33m[INFO] Execute: git submodule update --init --recursive evolution-go\033[0m"
    exit 1
fi

if [ "$BUILD_EVOLUTION" = true ]; then
    if [ ! -x "${EVOLUTION_PATCH_SCRIPT}" ]; then
        echo -e "\033[31m[ERROR] Script de patch do Evolution Go não encontrado em ${EVOLUTION_PATCH_SCRIPT}.\033[0m"
        exit 1
    fi

    "${EVOLUTION_PATCH_SCRIPT}" "${EVOLUTION_CONTEXT}"
fi

echo -e "\033[32m[BUILD] Building ${FULL_IMAGE} with tags: ${TAGS[*]}\033[0m"
if [ "$CAN_DEPLOY" = true ]; then
    echo -e "\033[36m[DEPLOY] Autodeploy ativo para a stack ${STACK_NAME}.\033[0m"
elif [ "$NO_DEPLOY" = true ]; then
    echo -e "\033[33m[DEPLOY] Autodeploy desabilitado via --no-deploy.\033[0m"
else
    echo -e "\033[33m[DEPLOY] Autodeploy indisponível; defina PORTAINER_URL e PORTAINER_API_KEY.\033[0m"
fi

if [ "$BUILD_EVOLUTION" = true ]; then
    echo -e "\033[36m[BUILD] Evolution Go incluído: ${EVOLUTION_IMAGE}\033[0m"
else
    echo -e "\033[33m[BUILD] Evolution Go ignorado via --skip-evolution.\033[0m"
fi

# Preparar argumentos de build
BUILD_ARGS=()
if [ "$DISABLE_TELEMETRY" = true ]; then
    echo -e "\033[32m[PRIVACY] Desabilitando telemetria na imagem...\033[0m"
    BUILD_ARGS+=(--build-arg DISABLE_TELEMETRY=true)
fi

build_image_with_tags "$FULL_IMAGE" "$DOCKERFILE" "." "${BUILD_ARGS[@]}"

if [ "$BUILD_EVOLUTION" = true ]; then
    build_image_with_tags "$EVOLUTION_IMAGE" "${EVOLUTION_CONTEXT}/Dockerfile" "$EVOLUTION_CONTEXT" --build-arg "VERSION=${PRIMARY_TAG}"
fi

echo -e "\033[32m[COMPLETE] Imagens criadas com sucesso:\033[0m"
for tag in "${TAGS[@]}"; do
    echo -e "\033[36m  -> ${FULL_IMAGE}:${tag}\033[0m"
    if [ "$BUILD_EVOLUTION" = true ]; then
        echo -e "\033[36m  -> ${EVOLUTION_IMAGE}:${tag}\033[0m"
    fi
done

# Push para o registry
if [ "$NO_PUSH" = false ]; then
    echo -e "\033[33m[PUSH] Iniciando push para o registro (padrão)...\033[0m"
    echo -e "\033[36m[INFO] Para desabilitar, use a flag --no-push.\033[0m"

    push_image_tags "$FULL_IMAGE"
    DEPLOY_IMAGE="${PUSHED_DEPLOY_IMAGE}"

    if [ "$BUILD_EVOLUTION" = true ]; then
        push_image_tags "$EVOLUTION_IMAGE"
        EVOLUTION_DEPLOY_IMAGE="${PUSHED_DEPLOY_IMAGE}"
    fi

    echo -e "\033[32m[COMPLETE] Todas as tags foram enviadas para o registro.\033[0m"

    if [ "$CAN_DEPLOY" = true ]; then
        echo -e "\033[33m[DEPLOY] Aguardando 5s para propagação da imagem no registry...\033[0m"
        sleep 5

        deploy_ok=0
        deploy_fail=0

        DEPLOY_TARGETS=(
            "chatwoot_sidekiq|${DEPLOY_IMAGE}"
            "chatwoot_app|${DEPLOY_IMAGE}"
        )

        if [ "$BUILD_EVOLUTION" = true ]; then
            DEPLOY_TARGETS+=("evolution_go|${EVOLUTION_DEPLOY_IMAGE}")
        fi

        for target in "${DEPLOY_TARGETS[@]}"; do
            service="${target%%|*}"
            image="${target#*|}"

            if force_update_service "$service" "$image"; then
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
        if [ "$BUILD_EVOLUTION" = true ]; then
            echo -e "\033[37m  docker push ${EVOLUTION_IMAGE}:${tag}\033[0m"
        fi
    done
fi

if [ "$DISABLE_TELEMETRY" = true ]; then
    echo ""
    echo -e "\033[32m[PRIVACY] TELEMETRIA DESABILITADA NA IMAGEM!\033[0m"
fi
