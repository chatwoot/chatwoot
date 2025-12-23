#!/bin/bash
# Script para instalar dependências do sistema necessárias para rodar o Chatwoot
# Execute este script com: bash SETUP_REQUIRED.sh

echo "Instalando dependências do sistema para compilar Ruby..."
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
  libpq-dev \
  postgresql \
  postgresql-contrib

echo ""
echo "Dependências instaladas!"
echo ""
echo "Agora execute os seguintes comandos:"
echo ""
echo "1. Configurar rbenv no seu shell:"
echo "   export PATH=\"\$HOME/.rbenv/bin:\$PATH\""
echo "   eval \"\$(rbenv init -)\""
echo ""
echo "2. Instalar Ruby 3.4.4:"
echo "   rbenv install 3.4.4"
echo "   rbenv local 3.4.4"
echo ""
echo "3. Instalar dependências Ruby:"
echo "   bundle install"
echo ""
echo "4. Configurar PostgreSQL:"
echo "   sudo -u postgres createuser -s \$USER"
echo "   sudo -u postgres createdb chatwoot_dev"
echo ""
echo "5. Configurar banco de dados:"
echo "   bundle exec rails db:create"
echo "   bundle exec rails db:migrate"
echo "   bundle exec rails db:seed"
echo ""
echo "6. Iniciar o sistema:"
echo "   pnpm dev"

