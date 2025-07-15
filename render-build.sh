#!/usr/bin/env bash

# 🛑 Desactiva pnpm por si Render lo activa por defecto
export COREPACK_ENABLE_PNPM=0

# ✅ Fuerza Yarn 1.22
corepack enable
corepack prepare yarn@1.22.22 --activate

# Instala dependencias de Node.js
yarn install

# Compila frontend con yarn
yarn build:production

# Instala gems de Ruby
bundle install

# Precompila assets
bundle exec rake assets:precompile
