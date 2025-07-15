#!/usr/bin/env bash

# Exit on error
set -o errexit

echo "🌱 Instalando dependencias con Yarn..."
yarn install --frozen-lockfile

echo "🔨 Compilando assets de frontend con Vite..."
yarn build

echo "💎 Instalando gems de Ruby..."
bundle install --without development test --path vendor/bundle

echo "📦 Precompilando assets de Rails..."
bundle exec rake assets:precompile

echo "🧹 Limpiando caché de Rails..."
bundle exec rake tmp:clear
