#!/bin/bash

# Fetch the latest changes from the upstream repository
git fetch upstream

# Check out the main branch of your repository
git checkout develop

# Merge the changes from the upstream repository into your main branch
git merge upstream/master

# Pull the latest changes from your remote repository
git pull origin develop

# Push the changes to your repository
git push origin develop

# Create a pull request using the GitHub CLI
gh pr create --title "Sync with upstream" --body "Automated sync with upstream repository"
