#!/bin/bash

# Development environment setup script
set -e

echo "🚀 Setting up Chatwoot TypeScript development environment..."

# Check if .env exists
if [ ! -f .env ]; then
  echo "📝 Creating .env file from .env.example..."
  cp .env.example .env
  echo "✅ .env file created. Please update it with your local configuration."
else
  echo "✅ .env file already exists."
fi

# Install dependencies
echo "📦 Installing dependencies..."
pnpm install

# Create logs directory
if [ ! -d logs ]; then
  echo "📁 Creating logs directory..."
  mkdir -p logs
fi

# Create storage directory
if [ ! -d storage ]; then
  echo "📁 Creating storage directory..."
  mkdir -p storage
fi

# Build the project
echo "🔨 Building the project..."
pnpm build

echo "✨ Development environment setup complete!"
echo ""
echo "Next steps:"
echo "1. Update .env with your database and Redis credentials"
echo "2. Run 'pnpm migration:run' to set up the database"
echo "3. Run 'pnpm start:dev' to start the development server"
