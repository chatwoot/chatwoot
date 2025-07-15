#!/usr/bin/env bash

export COREPACK_ENABLE_PNPM=0
corepack enable
corepack prepare yarn@1.22.22 --activate

# Instala dependencias de Node.js
yarn install

# Compila frontend con yarn
yarn build

# Instala gems de Ruby
bundle install

# Precompila assets
bundle exec rake assets:precompile
