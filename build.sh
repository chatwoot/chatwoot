#!/bin/bash

# Script de build de produção para Linux
# Baseado no build-producao.ps1

set -e  # Para na primeira falha

# Configurações padrão
VERSION="v4.10"
REGISTRY="witrocha"
IMAGE_NAME="chatwit"
LATEST=false
NO_ENTERPRISE=false
DISABLE_TELEMETRY=true
NO_CACHE=false
NO_PUSH=false

# Função de ajuda
show_help() {
    cat << EOF
Script de Build de Produção - Chatwit

USAGE:
    ./build-producao.sh [OPTIONS]

OPTIONS:
    -v, --version VERSION     Versão da imagem (padrão: v4.4)
    -r, --registry REGISTRY  Nome do registry (padrão: witrocha)
    -i, --image IMAGE         Nome da imagem (padrão: chatwit)
    -l, --latest              Adiciona tag 'latest'
    --no-enterprise           Usa Dockerfile padrão em vez do enterprise
    --enable-telemetry        Habilita telemetria (padrão: desabilitada)
    --no-cache                Build sem cache
    --no-push                 Não faz push para o registry
    -h, --help                Mostra esta ajuda

EXAMPLES:
    ./build-producao.sh -v v5.0.0 --latest
    ./build-producao.sh --no-push
    ./build-producao.sh --no-enterprise --latest

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

# Construir array de tags
TAGS=("$VERSION")
if [ "$LATEST" = true ]; then
    TAGS+=("latest")
fi

FULL_IMAGE="$REGISTRY/$IMAGE_NAME"

# Definir Dockerfile
if [ "$NO_ENTERPRISE" = true ]; then
    DOCKERFILE="Dockerfile"
    echo -e "\033[36m[INFO] Usando: Dockerfile (padrão)\033[0m"
else
    DOCKERFILE="Dockerfile.enterprise"
    echo -e "\033[36m[INFO] Usando: Dockerfile.enterprise\033[0m"
fi

echo -e "\033[32m[BUILD] Building ${FULL_IMAGE} with tags: ${TAGS[*]}\033[0m"

# Preparar argumentos de build
BUILD_ARGS=()
if [ "$DISABLE_TELEMETRY" = true ]; then
    echo -e "\033[32m[PRIVACY] Desabilitando telemetria na imagem...\033[0m"
    BUILD_ARGS+=(--build-arg DISABLE_TELEMETRY=true)
    BUILD_ARGS+=(--build-arg ANALYTICS_TOKEN=)
    BUILD_ARGS+=(--build-arg CHATWOOT_HUB_URL=http://localhost:9999)
fi

# Build com a primeira tag (versão principal)
PRIMARY_TAG="${TAGS[0]}"
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
        
        for tag in "${TAGS[@]}"; do
            echo -e "\033[36m[PUSH] Enviando ${FULL_IMAGE}:${tag}...\033[0m"
            docker push "${FULL_IMAGE}:${tag}"
            
            if [ $? -ne 0 ]; then
                echo -e "\033[31m[ERROR] Falha no push da tag ${tag}!\033[0m"
                exit 1
            else
                echo -e "\033[32m[SUCCESS] Push da tag ${tag} concluído.\033[0m"
            fi
        done
        
        echo -e "\033[32m[COMPLETE] Todas as tags foram enviadas para o registro.\033[0m"
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
