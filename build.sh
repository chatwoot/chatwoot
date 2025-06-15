#!/bin/bash
set -ex
export SHELL=/bin/bash
export NODE_OPTIONS="--max-old-space-size=2048"
npm install -g pnpm@10.2.0
corepack enable
corepack prepare pnpm@10.2.0 --activate
pnpm setup
bundle install
pnpm install --ignore-scripts=false --unsafe-perm=true
pnpm exec husky install
NODE_OPTIONS="--max-old-space-size=2048" pnpm run build:sdk
bundle exec rake assets:precompile
bundle exec rake assets:clean