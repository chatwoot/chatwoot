#!/bin/bash

# Script de inicialização do Chatwoot
# Autor: Hamiel
# Uso: ./start_chatwoot.sh

echo "🚀 Iniciando Chatwoot..."
echo "================================"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Função para verificar se um serviço está rodando
check_service() {
    if sudo systemctl is-active --quiet $1; then
        echo -e "${GREEN}✅ $1 já está rodando${NC}"
        return 0
    else
        echo -e "${YELLOW}⏳ Iniciando $1...${NC}"
        sudo systemctl start $1
        sleep 2
        if sudo systemctl is-active --quiet $1; then
            echo -e "${GREEN}✅ $1 iniciado com sucesso${NC}"
            return 0
        else
            echo -e "${RED}❌ Erro ao iniciar $1${NC}"
            return 1
        fi
    fi
}

# Verificar se estamos na pasta correta do Chatwoot
echo -e "${BLUE}�� Verificando diretório do Chatwoot...${NC}"
if [[ ! -f "Gemfile" ]] || [[ ! -f "config/application.rb" ]]; then
    echo -e "${RED}❌ Erro: Execute este script dentro da pasta do Chatwoot${NC}"
    echo -e "${YELLOW}💡 Use: cd ~/projetos/chatwoot && ./start_chatwoot.sh${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Estamos na pasta correta do Chatwoot${NC}"

# Verificar e iniciar PostgreSQL
echo -e "\n${BLUE}🐘 Verificando PostgreSQL...${NC}"
check_service postgresql

# Verificar e iniciar Redis
echo -e "\n${BLUE}🔴 Verificando Redis...${NC}"
check_service redis-server

# Verificar se os bancos de dados existem
echo -e "\n${BLUE}🗄️  Verificando bancos de dados...${NC}"
if rails runner "ActiveRecord::Base.connection" 2>/dev/null; then
    echo -e "${GREEN}✅ Banco de dados conectado${NC}"
else
    echo -e "${YELLOW}⚠️  Problema na conexão do banco. Verifique as configurações.${NC}"
fi

# Verificar Ruby e dependências
echo -e "\n${BLUE}💎 Verificando ambiente Ruby...${NC}"
echo -e "Ruby: ${GREEN}$(ruby -v)${NC}"
echo -e "Bundler: ${GREEN}$(bundle -v)${NC}"

# Verificar se as gems estão instaladas
if bundle check >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Gems instaladas${NC}"
else
    echo -e "${YELLOW}⚠️  Algumas gems podem estar faltando${NC}"
fi

echo -e "\n${GREEN}🎉 Inicialização concluída!${NC}"
echo "================================"
echo -e "${BLUE}Para iniciar o Chatwoot, execute os comandos abaixo em terminais separados:${NC}"
echo ""
echo -e "${YELLOW}Terminal 1 - Servidor Rails:${NC}"
echo "./bin/rails server"
echo ""
echo -e "${YELLOW}Terminal 2 - Background Jobs (Sidekiq):${NC}"
echo "bundle exec sidekiq"
echo ""
echo -e "${BLUE}Depois acesse: ${GREEN}http://localhost:3000${NC}"
echo -e "${BLUE}Login: ${GREEN}hamielhenrique29@gmail.com${NC}"
echo ""

# Opção para executar automaticamente (comentada por padrão)
# echo -e "${YELLOW}Deseja iniciar automaticamente os servidores? (y/n)${NC}"
# read -r response
# if [[ "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
#     echo -e "${BLUE}Iniciando servidores...${NC}"
#     gnome-terminal -- bash -c "cd ~/projetos/chatwoot && bin/rails server; exec bash" &
#     gnome-terminal -- bash -c "cd ~/projetos/chatwoot && bundle exec sidekiq; exec bash" &
#     echo -e "${GREEN}Servidores iniciados em terminais separados!${NC}"
# fi
