# Portainer Auto-Deployment Setup Guide

This guide will help you set up automatic deployment from GitHub to Portainer.

## Overview

When you push code to the `develop` branch:
1. GitHub Actions builds a Docker image
2. The image is pushed to GitHub Container Registry (ghcr.io)
3. Portainer is notified via webhook to pull and redeploy the new image

## Step 1: Create a Portainer Webhook

1. Go to https://portainer.unlockingtech.com
2. Navigate to your Chatwoot stack/container
3. Click on the container you want to auto-update
4. Scroll down to **"Webhooks"** section
5. Click **"Add webhook"**
6. Copy the webhook URL (it will look like: `https://portainer.unlockingtech.com/api/webhooks/xxx-xxx-xxx`)
7. Save it for Step 2

## Step 2: Add Webhook URL to GitHub Secrets

1. Go to https://github.com/qtoino/chatwoot/settings/secrets/actions
2. Click **"New repository secret"**
3. Name: `PORTAINER_WEBHOOK_URL`
4. Value: Paste the webhook URL from Step 1
5. Click **"Add secret"**

## Step 3: Configure Portainer to Use GitHub Container Registry

### Option A: Using GitHub Container Registry (Recommended)

1. In Portainer, go to **"Registries"**
2. Click **"Add registry"**
3. Select **"Custom registry"**
4. Fill in:
   - **Name**: `GitHub Container Registry`
   - **Registry URL**: `ghcr.io`
   - **Username**: Your GitHub username (e.g., `qtoino`)
   - **Password**: GitHub Personal Access Token (see below)
5. Click **"Add registry"**

### Creating a GitHub Personal Access Token:

1. Go to https://github.com/settings/tokens
2. Click **"Generate new token (classic)"**
3. Name: `Portainer Registry Access`
4. Expiration: Choose appropriate expiration
5. Select scopes:
   - ✅ `read:packages` (to pull images)
6. Click **"Generate token"**
7. Copy the token and use it as the password in Portainer

## Step 4: Update Your Portainer Stack/Container

1. In Portainer, edit your Chatwoot container/stack
2. Update the image to: `ghcr.io/qtoino/chatwoot:latest`
3. Enable **"Always pull image"** option
4. Save changes

## Step 5: Test the Deployment

1. Make a change to your code
2. Commit and push to the `develop` branch:
   ```bash
   git add .
   git commit -m "Test auto-deployment"
   git push origin develop
   ```
3. Go to https://github.com/qtoino/chatwoot/actions
4. You should see the workflow running
5. Once complete, Portainer will automatically redeploy

## Troubleshooting

### Workflow fails at "Build and push Docker image"
- Check that the Dockerfile exists at `docker/Dockerfile`
- Make sure you have GitHub Actions enabled in your repository

### Webhook doesn't trigger
- Verify the webhook URL is correct in GitHub secrets
- Check Portainer logs for webhook errors

### Image pull fails in Portainer
- Verify the GitHub Container Registry credentials are correct
- Make sure your GitHub token has `read:packages` permission
- Check that the image name matches: `ghcr.io/qtoino/chatwoot:latest`

## What Gets Built

The workflow uses the existing Dockerfile at:
- `docker/Dockerfile`

The image will be tagged as:
- `ghcr.io/qtoino/chatwoot:develop` (branch name)
- `ghcr.io/qtoino/chatwoot:develop-<commit-sha>` (specific commit)
- `ghcr.io/qtoino/chatwoot:latest` (latest from develop)

## Viewing Your Container Images

You can view all built images at:
https://github.com/qtoino/chatwoot/pkgs/container/chatwoot
