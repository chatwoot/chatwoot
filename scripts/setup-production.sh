#!/bin/bash

# VegaVision Production Runner Setup Script
# Run this script on any VM where you want to set up a GitLab runner for VegaVision deployments
# This script prepares the environment for multiple organization deployments

set -e

echo "🚀 Setting up VegaVision GitLab runner environment..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    echo "⚠️  Please log out and log back in for Docker group membership to take effect"
else
    echo "✅ Docker already installed"
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    echo "🔧 Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "✅ Docker Compose already installed"
fi

# Create base directories for multi-org deployments
echo "� Creating base deployment structure..."
mkdir -p ~/deployments
mkdir -p /vv-volumes

# Create shared Docker network for all VegaVision deployments
echo "🌐 Creating shared Docker network..."
docker network create vv-helpdesk 2>/dev/null || echo "✅ Network vv-helpdesk already exists"

# Install GitLab Runner if not present
if ! command -v gitlab-runner &> /dev/null; then
    echo "🏃 Installing GitLab Runner..."
    curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
    sudo apt-get install gitlab-runner -y
else
    echo "✅ GitLab Runner already installed"
fi

echo "✅ GitLab Runner environment setup complete!"
echo ""
echo "🔑 Next steps:"
echo "1. Register GitLab Runner with your GitLab instance:"
echo "   sudo gitlab-runner register \\"
echo "     --url 'https://your-gitlab-instance.com/' \\"
echo "     --token 'your-registration-token' \\"
echo "     --executor 'docker' \\"
echo "     --docker-image 'docker:24.0.5' \\"
echo "     --tag-list 'self-hosted' \\"
echo "     --run-untagged='false' \\"
echo "     --locked='false'"
echo ""
echo "2. Configure GitLab CI/CD Variables for each organization:"
echo "   - ORG: Organization identifier (e.g., 'acme', 'client1')"
echo "   - SECURE_FILES_TOKEN: Token with read_api scope"
echo "   - DOCKER_HUB_USERNAME and DOCKER_HUB_PASSWORD"
echo "   - FRONTEND_URL: Organization's domain"
echo ""
echo "3. Upload organization-specific .env files to GitLab Secure Files"
echo ""
echo "📋 System Info:"
echo "Docker version: $(docker --version)"
echo "Docker Compose version: $(docker-compose --version)"
echo "GitLab Runner version: $(gitlab-runner --version 2>/dev/null || echo 'Not installed')"
echo "Base deployment directory: ~/deployments"
echo "Shared volumes directory: /vv-volumes"
echo "Shared network: vv-helpdesk"
echo ""
echo "🏢 Multi-Organization Support:"
echo "This runner can deploy multiple VegaVision instances:"
echo "   - Each org gets: ~/vv-\$ORG-helpdesk/ directory"
echo "   - Containers named: vv-\$ORG-helpdesk-Rails, vv-\$ORG-helpdesk-Sidekiq, etc."
echo "   - Volumes at: /vv-volumes/\$ORG-helpdesk/"
echo "   - All share the 'vv-helpdesk' network for NPM integration"
echo ""
echo "🌐 For NPM (Nginx Proxy Manager) integration:"
echo "   - Connect NPM container to 'vv-helpdesk' network"
echo "   - Proxy each org to: vv-\$ORG-helpdesk-Rails:3000"
echo "   - Example: acme.domain.com → vv-acme-helpdesk-Rails:3000"
