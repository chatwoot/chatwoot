#!/bin/bash

# Get deploy environmet
if [[ $BRANCH_NAME = 'trunk' ]]; then
    deploy_environment="production"
elif [[ $BRANCH_NAME = 'develop' ]]; then
    deploy_environment="staging"
else
    deploy_environment="development"
fi

# Get GithubActionURL
github_action_url="https://github.com/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID"

echo "payload={ \"repository_name\": \"$GITHUB_REPOSITORY\", \"enviroment\": \"$deploy_environment\", \"status\": \"$JOB_STATUS\", \"action_url\": \"$github_action_url\" }" >> $GITHUB_OUTPUT
