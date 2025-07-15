#!/usr/bin/env bash

echo "📦 Installing Ruby dependencies..."
bundle install

echo "📦 Installing JS dependencies..."
yarn install --frozen-lockfile

echo "🛠️ Precompiling Rails assets..."
bundle exec rails assets:precompile
