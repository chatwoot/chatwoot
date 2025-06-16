set -ex

export SHELL=/bin/bash
export NODE_OPTIONS="--max-old-space-size=3072"

time npm install -g pnpm@10.2.0
time corepack enable
time corepack prepare pnpm@10.2.0 --activate

time pnpm setup
time bundle install
time pnpm install --ignore-scripts=false --unsafe-perm=true
time pnpm exec husky install

time pnpm run build:sdk

time bundle exec rake assets:precompile
time bundle exec rake ass
