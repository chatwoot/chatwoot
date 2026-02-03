#!/bin/bash

# Helper script para operações comuns de deploy
# Uso: bash deploy-helper.sh [comando]

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
VPS_USER="${SSH_USER:-root}"
VPS_HOST="${SSH_HOST:-}"
VPS_PORT="${SSH_PORT:-22}"
DEPLOY_DIR="~/chatwoot-heycommerce"

# Funções auxiliares
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

check_ssh_config() {
    if [ -z "$VPS_HOST" ]; then
        print_error "SSH_HOST não configurado!"
        echo "Configure as variáveis de ambiente ou edite o script."
        exit 1
    fi
}

# Comandos disponíveis

cmd_status() {
    print_header "Status da Stack Chatwoot"
    check_ssh_config
    
    ssh -p $VPS_PORT $VPS_USER@$VPS_HOST << 'EOF'
        echo "=== Stack Status ==="
        docker stack ps chatwoot
        echo ""
        echo "=== Services ==="
        docker service ls | grep chatwoot
EOF
    
    print_success "Status verificado"
}

cmd_logs() {
    print_header "Logs do Chatwoot"
    check_ssh_config
    
    SERVICE=${1:-chatwoot_chatwoot_app}
    LINES=${2:-100}
    
    echo "Serviço: $SERVICE"
    echo "Linhas: $LINES"
    echo ""
    
    ssh -p $VPS_PORT $VPS_USER@$VPS_HOST "docker service logs $SERVICE -f --tail $LINES"
}

cmd_console() {
    print_header "Rails Console"
    check_ssh_config
    
    ssh -t -p $VPS_PORT $VPS_USER@$VPS_HOST << 'EOF'
        CONTAINER_ID=$(docker ps -q -f name=chatwoot_chatwoot_app | head -n1)
        if [ -z "$CONTAINER_ID" ]; then
            echo "Erro: Container não encontrado!"
            exit 1
        fi
        docker exec -it $CONTAINER_ID bundle exec rails console
EOF
}

cmd_bash() {
    print_header "Bash no Container"
    check_ssh_config
    
    ssh -t -p $VPS_PORT $VPS_USER@$VPS_HOST << 'EOF'
        CONTAINER_ID=$(docker ps -q -f name=chatwoot_chatwoot_app | head -n1)
        if [ -z "$CONTAINER_ID" ]; then
            echo "Erro: Container não encontrado!"
            exit 1
        fi
        docker exec -it $CONTAINER_ID bash
EOF
}

cmd_rollback() {
    print_header "Rollback de Serviços"
    check_ssh_config
    
    print_warning "Isso vai fazer rollback para a versão anterior!"
    read -p "Continuar? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Operação cancelada"
        exit 0
    fi
    
    ssh -p $VPS_PORT $VPS_USER@$VPS_HOST << 'EOF'
        echo "Rollback do app..."
        docker service rollback chatwoot_chatwoot_app
        
        echo "Rollback do worker..."
        docker service rollback chatwoot_chatwoot_worker
        
        echo "Aguardando convergência..."
        sleep 10
        
        echo "Status:"
        docker service ps chatwoot_chatwoot_app --no-trunc | head -n 5
EOF
    
    print_success "Rollback concluído"
}

cmd_restart() {
    print_header "Restart de Serviços"
    check_ssh_config
    
    SERVICE=${1:-all}
    
    if [ "$SERVICE" = "all" ]; then
        print_warning "Reiniciando todos os serviços..."
        ssh -p $VPS_PORT $VPS_USER@$VPS_HOST << 'EOF'
            docker service update --force chatwoot_chatwoot_app
            docker service update --force chatwoot_chatwoot_worker
EOF
    else
        print_warning "Reiniciando serviço: $SERVICE"
        ssh -p $VPS_PORT $VPS_USER@$VPS_HOST "docker service update --force $SERVICE"
    fi
    
    print_success "Restart iniciado"
}

cmd_scale() {
    print_header "Escalar Serviços"
    check_ssh_config
    
    SERVICE=${1:-chatwoot_chatwoot_worker}
    REPLICAS=${2:-1}
    
    print_warning "Escalando $SERVICE para $REPLICAS réplicas..."
    ssh -p $VPS_PORT $VPS_USER@$VPS_HOST "docker service scale $SERVICE=$REPLICAS"
    
    print_success "Serviço escalado"
}

cmd_cleanup() {
    print_header "Limpeza de Volumes"
    check_ssh_config
    
    print_warning "Isso vai limpar o volume chatwoot_public!"
    read -p "Continuar? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Operação cancelada"
        exit 0
    fi
    
    ssh -p $VPS_PORT $VPS_USER@$VPS_HOST << 'EOF'
        docker run --rm \
            -v chatwoot_public:/data \
            alpine:latest \
            sh -c "rm -rf /data/* /data/.[!.]* /data/..?* 2>/dev/null || true && echo 'Volume limpo'"
EOF
    
    print_success "Limpeza concluída"
}

cmd_image() {
    print_header "Informações da Imagem"
    check_ssh_config
    
    ssh -p $VPS_PORT $VPS_USER@$VPS_HOST << 'EOF'
        echo "=== Imagem em uso (App) ==="
        docker service inspect chatwoot_chatwoot_app --format='{{.Spec.TaskTemplate.ContainerSpec.Image}}'
        
        echo ""
        echo "=== Imagem em uso (Worker) ==="
        docker service inspect chatwoot_chatwoot_worker --format='{{.Spec.TaskTemplate.ContainerSpec.Image}}'
        
        echo ""
        echo "=== Imagens disponíveis localmente ==="
        docker images | grep chatwoot-heycommerce
EOF
}

cmd_help() {
    cat << EOF
🚀 Deploy Helper - Chatwoot HeyCommerce

Uso: bash deploy-helper.sh [comando] [argumentos]

Comandos disponíveis:

  status              - Ver status da stack e serviços
  logs [serviço] [n]  - Ver logs (padrão: app, 100 linhas)
  console             - Abrir Rails console
  bash                - Abrir bash no container
  rollback            - Fazer rollback para versão anterior
  restart [serviço]   - Reiniciar serviços (padrão: all)
  scale [serviço] [n] - Escalar serviço (padrão: worker, 1)
  cleanup             - Limpar volume chatwoot_public
  image               - Ver informações das imagens
  help                - Mostrar esta ajuda

Exemplos:

  bash deploy-helper.sh status
  bash deploy-helper.sh logs chatwoot_chatwoot_worker 200
  bash deploy-helper.sh console
  bash deploy-helper.sh restart chatwoot_chatwoot_app
  bash deploy-helper.sh scale chatwoot_chatwoot_worker 2

Variáveis de ambiente (opcional):

  SSH_HOST  - IP ou domínio da VPS
  SSH_USER  - Usuário SSH (padrão: root)
  SSH_PORT  - Porta SSH (padrão: 22)

Exemplo com variáveis:
  SSH_HOST=192.168.1.100 SSH_USER=ubuntu bash deploy-helper.sh status

EOF
}

# Main
COMMAND=${1:-help}

case $COMMAND in
    status)
        cmd_status
        ;;
    logs)
        cmd_logs "$2" "$3"
        ;;
    console)
        cmd_console
        ;;
    bash)
        cmd_bash
        ;;
    rollback)
        cmd_rollback
        ;;
    restart)
        cmd_restart "$2"
        ;;
    scale)
        cmd_scale "$2" "$3"
        ;;
    cleanup)
        cmd_cleanup
        ;;
    image)
        cmd_image
        ;;
    help|--help|-h)
        cmd_help
        ;;
    *)
        print_error "Comando desconhecido: $COMMAND"
        echo ""
        cmd_help
        exit 1
        ;;
esac
