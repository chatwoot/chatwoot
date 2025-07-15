#!/usr/bin/env bash

# Activa Yarn 1.x
corepack enable
corepack prepare yarn@1.22.22 --activate

# Instala dependencias de Node.js
yarn install

# Compila el frontend con Vite
yarn build:production

# Precompila los assets de Rails
bundle exec rake assets:precompile
