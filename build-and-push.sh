#!/bin/bash
# Script para build e push da imagem Docker

set -e

IMAGE_NAME="houi/chatkivo:v0.1"
DOCKERFILE="docker/Dockerfile"

echo "=========================================="
echo "Build e Push - Chatwoot Customizado"
echo "=========================================="
echo "Imagem: $IMAGE_NAME"
echo ""

# Verificar Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker não encontrado. Por favor, instale o Docker primeiro."
    exit 1
fi

# Verificar se Docker está rodando
if ! docker info &> /dev/null; then
    echo "❌ Docker não está rodando. Por favor, inicie o Docker primeiro."
    exit 1
fi

echo "✅ Docker está rodando"
echo ""

# Verificar login no Docker Hub
echo "📋 Verificando login no Docker Hub..."
if docker info 2>/dev/null | grep -q "Username"; then
    USERNAME=$(docker info 2>/dev/null | grep "Username" | awk '{print $2}' || echo "")
    if [ -n "$USERNAME" ]; then
        echo "✅ Logado como: $USERNAME"
    else
        echo "⚠️  Não foi possível verificar o usuário. Continuando..."
    fi
else
    echo "⚠️  Você pode precisar fazer login: docker login"
    echo "   Continuando com o build..."
fi
echo ""

# Build da imagem
echo "🔨 Iniciando build da imagem..."
echo "   Isso pode levar 10-20 minutos dependendo da sua conexão..."
echo ""

docker build -t $IMAGE_NAME -f $DOCKERFILE . --progress=plain

BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ Build concluído com sucesso!"
    echo ""
    
    # Mostrar informações da imagem
    echo "📦 Informações da imagem:"
    docker images $IMAGE_NAME
    echo ""
    
    # Perguntar se quer fazer push
    read -p "Deseja fazer push para o Docker Hub agora? (s/n): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[SsYy]$ ]]; then
        echo ""
        echo "🚀 Fazendo push para Docker Hub..."
        echo "   Repositório será criado automaticamente no primeiro push"
        echo ""
        
        docker push $IMAGE_NAME
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "=========================================="
            echo "✅ Push concluído com sucesso!"
            echo "=========================================="
            echo ""
            echo "Imagem disponível em: $IMAGE_NAME"
            echo "Verifique em: https://hub.docker.com/r/houi/chatkivo"
            echo ""
        else
            echo ""
            echo "❌ Erro no push. Verifique:"
            echo "   1. Se está logado: docker login"
            echo "   2. Se tem permissão no repositório houi/chatkivo"
            exit 1
        fi
    else
        echo ""
        echo "ℹ️  Build concluído. Para fazer push depois, execute:"
        echo "   docker push $IMAGE_NAME"
    fi
else
    echo ""
    echo "❌ Erro no build da imagem (código: $BUILD_EXIT_CODE)"
    echo "   Verifique os logs acima para mais detalhes"
    exit 1
fi
