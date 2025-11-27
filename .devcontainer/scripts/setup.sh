#!/bin/bash
set -e  # Exit on error

echo "Setting up Chatwoot development environment..."

# Copy environment file
cp .env.example .env

# Check if running in Codespaces or locally
if [ -n "$CODESPACE_NAME" ]; then
  echo "Running in GitHub Codespaces..."

  # Codespace configuration
  sed -i -e '/REDIS_URL/ s/=.*/=redis:\/\/localhost:6379/' .env
  sed -i -e '/POSTGRES_HOST/ s/=.*/=localhost/' .env
  sed -i -e '/POSTGRES_USERNAME/ s/=.*/=postgres/' .env
  sed -i -e '/POSTGRES_PASSWORD/ s/=.*/=postgres/' .env
  sed -i -e '/SMTP_ADDRESS/ s/=.*/=localhost/' .env
  sed -i -e "/FRONTEND_URL/ s/=.*/=https:\/\/$CODESPACE_NAME-3000.app.github.dev/" .env

  # Setup Claude Code API key if available
  if [ -n "$CLAUDE_CODE_API_KEY" ]; then
    mkdir -p ~/.claude
    echo '{"apiKeyHelper": "~/.claude/anthropic_key.sh"}' > ~/.claude/settings.json
    echo "echo \"$CLAUDE_CODE_API_KEY\"" > ~/.claude/anthropic_key.sh
    chmod +x ~/.claude/anthropic_key.sh
  fi

  # Make ports public in Codespaces
  gh codespace ports visibility 3000:public 3036:public 8025:public -c $CODESPACE_NAME || echo "Failed to set port visibility, continuing..."

else
  echo "Running locally in devcontainer..."

  # Local devcontainer also uses localhost because of network_mode: service:db
  sed -i -e '/REDIS_URL/ s/=.*/=redis:\/\/localhost:6379/' .env
  sed -i -e '/POSTGRES_HOST/ s/=.*/=localhost/' .env
  sed -i -e '/POSTGRES_USERNAME/ s/=.*/=postgres/' .env
  sed -i -e '/POSTGRES_PASSWORD/ s/=.*/=postgres/' .env
  sed -i -e '/SMTP_ADDRESS/ s/=.*/=localhost/' .env
  sed -i -e "/FRONTEND_URL/ s/=.*/=http:\/\/localhost:3000/" .env
fi

echo "Environment setup complete!"
