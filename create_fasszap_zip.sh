#!/bin/bash

# FassZap ZIP Creator for EasyPanel
# This script creates a complete ZIP package ready for EasyPanel deployment

echo "🧡 Creating FassZap ZIP package for EasyPanel..."

# Create temporary directory
TEMP_DIR="fasszap-easypanel"
ZIP_NAME="fasszap-easypanel.zip"

# Remove existing temp directory and zip
rm -rf $TEMP_DIR
rm -f $ZIP_NAME

# Create directory structure
mkdir -p $TEMP_DIR

echo "📁 Creating directory structure..."

# Copy core application files (only modified ones)
mkdir -p $TEMP_DIR/config/initializers
mkdir -p $TEMP_DIR/lib
mkdir -p $TEMP_DIR/enterprise/config
mkdir -p $TEMP_DIR/enterprise/app/services/fabiana
mkdir -p $TEMP_DIR/enterprise/app/services/llm
mkdir -p $TEMP_DIR/enterprise/app/controllers/api/v1/accounts/fabiana
mkdir -p $TEMP_DIR/app/assets/stylesheets/administrate/utilities
mkdir -p $TEMP_DIR/app/assets/stylesheets/administrate/library
mkdir -p $TEMP_DIR/app/helpers/super_admin
mkdir -p $TEMP_DIR/theme
mkdir -p $TEMP_DIR/public
mkdir -p $TEMP_DIR/db/migrate
mkdir -p $TEMP_DIR/bin

echo "📋 Copying configuration files..."

# Core configuration files
cp config/installation_config.yml $TEMP_DIR/config/
cp config/initializers/fasszap_enterprise.rb $TEMP_DIR/config/initializers/
cp lib/chatwoot_hub.rb $TEMP_DIR/lib/
cp lib/chatwoot_app.rb $TEMP_DIR/lib/

# Enterprise configuration
cp enterprise/config/premium_features.yml $TEMP_DIR/enterprise/config/
cp enterprise/config/premium_installation_config.yml $TEMP_DIR/enterprise/config/

# Fabiana AI services
cp -r enterprise/app/services/fabiana/* $TEMP_DIR/enterprise/app/services/fabiana/
cp enterprise/app/services/llm/base_open_ai_service.rb $TEMP_DIR/enterprise/app/services/llm/
cp -r enterprise/app/controllers/api/v1/accounts/fabiana/* $TEMP_DIR/enterprise/app/controllers/api/v1/accounts/fabiana/

# Styling files
cp app/assets/stylesheets/administrate/utilities/_variables.scss $TEMP_DIR/app/assets/stylesheets/administrate/utilities/
cp app/assets/stylesheets/administrate/library/_variables.scss $TEMP_DIR/app/assets/stylesheets/administrate/library/
cp theme/colors.js $TEMP_DIR/theme/

# Helper files
cp app/helpers/super_admin/features.yml $TEMP_DIR/app/helpers/super_admin/

# Public files
cp public/manifest.json $TEMP_DIR/public/

# Database migration
cp db/migrate/20241212000001_enable_fasszap_enterprise.rb $TEMP_DIR/db/migrate/

# Scripts
cp bin/fasszap_setup $TEMP_DIR/bin/
cp bin/fasszap_test $TEMP_DIR/bin/
chmod +x $TEMP_DIR/bin/fasszap_setup $TEMP_DIR/bin/fasszap_test

echo "🐳 Copying Docker files..."

# Docker files
cp Dockerfile.fasszap $TEMP_DIR/Dockerfile
cp docker-compose.easypanel.yml $TEMP_DIR/docker-compose.yml

# EasyPanel configuration
cp easypanel.yml $TEMP_DIR/

echo "📚 Copying documentation..."

# Documentation
cp README_FASSZAP.md $TEMP_DIR/
cp DEPLOY_EASYPANEL.md $TEMP_DIR/

echo "⚙️ Creating additional configuration files..."

# Create .env.example
cat > $TEMP_DIR/.env.example << 'EOF'
# FassZap Environment Configuration for EasyPanel

# Core Configuration
SECRET_KEY_BASE=cb26527b7f0b99738ed6ac1a65992340
FRONTEND_URL=https://your-domain.com
DEFAULT_LOCALE=pt_BR
FORCE_SSL=false
ENABLE_ACCOUNT_SIGNUP=true

# Enterprise Configuration (DO NOT CHANGE)
CW_EDITION=enterprise
INSTALLATION_PRICING_PLAN=enterprise
INSTALLATION_PRICING_PLAN_QUANTITY=10

# Database Configuration
POSTGRES_DATABASE=fasszap_production
POSTGRES_HOST=db
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=your_secure_password_here

# Redis Configuration
REDIS_URL=redis://redis:6379
REDIS_PASSWORD=your_redis_password_here

# Notifications (KEEP AS IS)
CHATWOOT_HUB_URL=https://hub.2.chatwoot.com
DISABLE_TELEMETRY=false

# Fabiana AI Configuration (Optional)
FABIANA_AI_PROVIDER=openai
FABIANA_OPEN_AI_API_KEY=sk-your_openai_key_here
FABIANA_OPEN_AI_MODEL=gpt-4o-mini
FABIANA_CHATGPT_API_KEY=sk-your_chatgpt_key_here
FABIANA_CHATGPT_MODEL=gpt-4
FABIANA_GROQ_API_KEY=gsk_your_groq_key_here
FABIANA_GROQ_MODEL=llama3-8b-8192

# Rails Configuration
RAILS_ENV=production
NODE_ENV=production
RAILS_MAX_THREADS=5
SIDEKIQ_CONCURRENCY=25
INSTALLATION_ENV=docker
TRUSTED_PROXIES=*
EOF

# Create startup script for EasyPanel
cat > $TEMP_DIR/start.sh << 'EOF'
#!/bin/bash
echo "🧡 Starting FassZap..."

# Wait for database
echo "⏳ Waiting for database..."
while ! pg_isready -h $POSTGRES_HOST -U $POSTGRES_USERNAME; do
  sleep 2
done

# Prepare database
echo "🗄️ Preparing database..."
bundle exec rails db:chatwoot_prepare

# Run FassZap setup
echo "⚙️ Running FassZap setup..."
./bin/fasszap_setup

# Start server
echo "🚀 Starting FassZap server..."
bundle exec rails server -b 0.0.0.0 -p 3000
EOF

chmod +x $TEMP_DIR/start.sh

# Create quick setup guide
cat > $TEMP_DIR/QUICK_START.md << 'EOF'
# 🚀 FassZap Quick Start for EasyPanel

## 1. Upload & Deploy
1. Upload this ZIP to EasyPanel
2. Extract in your project
3. EasyPanel will auto-detect docker-compose.yml

## 2. Configure Environment
Set these variables in EasyPanel:
- `SECRET_KEY_BASE` - Generate a secure key
- `FRONTEND_URL` - Your domain URL
- `POSTGRES_PASSWORD` - Secure database password
- `REDIS_PASSWORD` - Secure Redis password

## 3. Optional: Configure Fabiana AI
- `FABIANA_OPEN_AI_API_KEY` - Your OpenAI API key
- `FABIANA_GROQ_API_KEY` - Your Groq API key
- `FABIANA_AI_PROVIDER` - Choose: openai, chatgpt, or groq

## 4. Deploy & Access
1. Deploy the stack
2. Wait 2-3 minutes for initialization
3. Access your FassZap instance
4. Create admin account

## 🎉 Done!
Your FassZap is ready with:
- ✅ Enterprise features enabled
- ✅ Orange theme
- ✅ Fabiana AI ready
- ✅ Push notifications working

For detailed instructions, see DEPLOY_EASYPANEL.md
EOF

echo "📦 Creating ZIP package..."

# Create the ZIP file
zip -r $ZIP_NAME $TEMP_DIR/

# Clean up
rm -rf $TEMP_DIR

echo ""
echo "🎉 FassZap ZIP package created successfully!"
echo ""
echo "📦 Package: $ZIP_NAME"
echo "📊 Size: $(du -h $ZIP_NAME | cut -f1)"
echo ""
echo "🚀 Ready for EasyPanel deployment!"
echo ""
echo "📋 Next steps:"
echo "  1. Upload $ZIP_NAME to EasyPanel"
echo "  2. Extract in your project"
echo "  3. Configure environment variables"
echo "  4. Deploy the stack"
echo ""
echo "📚 See DEPLOY_EASYPANEL.md for detailed instructions"
echo ""
echo "🧡 FassZap - Enterprise Customer Support Platform"
EOF
