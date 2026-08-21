#!/usr/bin/env bash
docker rm -f cw-rails cw-sidekiq cw-vite 2>/dev/null || true
echo "stopped"
