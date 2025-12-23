#!/bin/bash
# Script completo para instalar tudo necessário para rodar o Chatwoot
# Execute com: bash INSTALL_EVERYTHING.sh

set -e

echo "=========================================="
echo "Instalando dependências do sistema..."
echo "=========================================="
sudo apt update
sudo apt install -y \
  build-essential \
  libssl-dev \
  libyaml-dev \
  libreadline-dev \
  zlib1g-dev \
  libncurses5-dev \
  libffi-dev \
  libgdbm-dev \
  libpq-dev

echo ""
echo "=========================================="
echo "Configurando rbenv..."
echo "=========================================="
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

echo ""
echo "=========================================="
echo "Instalando Ruby 3.4.4 (isso pode levar alguns minutos)..."
echo "=========================================="
rbenv install 3.4.4
rbenv local 3.4.4

echo ""
echo "=========================================="
echo "Instalando dependências Ruby..."
echo "=========================================="
bundle install

echo ""
echo "=========================================="
echo "Configurando banco de dados..."
echo "=========================================="
bundle exec rails db:create
bundle exec rails db:migrate
bundle exec rails db:seed

echo ""
echo "=========================================="
echo "✅ Tudo instalado e configurado!"
echo "=========================================="
echo ""
echo "Para iniciar o sistema, execute:"
echo "  pnpm dev"
echo ""

