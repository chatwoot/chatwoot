#!/bin/bash

# GitLab Secure Files Token Generator
# This script helps you create the necessary token for GitLab Secure Files API access

echo "🔑 GitLab Secure Files Token Setup"
echo "=================================="
echo ""

echo "📋 Steps to create SECURE_FILES_TOKEN:"
echo ""
echo "1. Go to your GitLab instance:"
echo "   → User Settings → Access Tokens"
echo "   OR"
echo "   → Project Settings → Access Tokens (for project-specific token)"
echo ""
echo "2. Create a new token with these settings:"
echo "   • Name: vegavision-secure-files"
echo "   • Expiration: Set based on your security policy"
echo "   • Scopes: ✅ read_api"
echo ""
echo "3. Copy the generated token and add it to:"
echo "   → Project Settings → CI/CD → Variables"
echo "   • Key: SECURE_FILES_TOKEN"
echo "   • Value: glpat-xxxxxxxxxxxxxxxx"
echo "   • Type: Variable"
echo "   • Flags: ✅ Mask variable"
echo ""
echo "4. Upload your .env file to:"
echo "   → Project Settings → CI/CD → Secure Files"
echo "   • File name must be exactly: .env"
echo ""

# Check if we can access GitLab API (if token is provided)
if [ ! -z "$GITLAB_TOKEN" ]; then
    echo "🔍 Testing GitLab API access..."
    
    read -p "Enter your GitLab instance URL (e.g., https://gitlab.com): " GITLAB_URL
    read -p "Enter your Project ID: " PROJECT_ID
    
    # Test API access
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
        "$GITLAB_URL/api/v4/projects/$PROJECT_ID")
    
    if [ "$response" = "200" ]; then
        echo "✅ Token has valid API access"
        
        # Check if secure files exist
        files=$(curl -s -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
            "$GITLAB_URL/api/v4/projects/$PROJECT_ID/secure_files")
        
        if echo "$files" | grep -q '\.env'; then
            echo "✅ .env file found in Secure Files"
        else
            echo "⚠️  .env file not found in Secure Files - make sure to upload it"
        fi
    else
        echo "❌ Token validation failed (HTTP $response)"
        echo "Check your token permissions and project access"
    fi
fi

echo ""
echo "🎯 Required GitLab CI/CD Variables:"
echo "• SECURE_FILES_TOKEN (masked)"
echo "• DOCKER_HUB_USERNAME"
echo "• DOCKER_HUB_PASSWORD (masked)"
echo "• FRONTEND_URL"
echo ""
echo "📁 Required Secure Files:"
echo "• .env (your production environment file)"
echo ""
echo "🏃 Runner Requirements:"
echo "• GitLab runner with 'self-hosted' tag"
echo "• Docker executor configured"
echo "• Access to Docker Hub (or your registry)"
