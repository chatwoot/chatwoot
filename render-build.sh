#!/usr/bin/env bash

# Yarn v1
corepack enable
corepack prepare yarn@1.22.22 --activate

# Node (frontend)
yarn install
yarn build:production

# Ruby (backend)
bundle install
bundle exec rake assets:precompile
