#!/bin/sh

#variables
REGION=$(printf '%s\n' "${AWS_DEFAULT_REGION}")
SERVICE_NAME=$(printf '%s\n' "${SERVICE_NAME}")
CLUSTER_NAME=$(printf '%s\n' "${CLUSTER_NAME}")
REPOSITORY_URI_VERSION=$(printf '%s\n' "${REPOSITORY_URI_VERSION}")

echo "Deploying service: $SERVICE_NAME"
echo "Image: $REPOSITORY_URI_VERSION"
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"

#getting old task definition from full list
TASK_DEF_OLD_ARN=$(aws ecs list-task-definitions | jq -r ' .taskDefinitionArns[] | select( . | contains("'${SERVICE_NAME}'"))' | tail -1)

if [ -z "$TASK_DEF_OLD_ARN" ] || [ "$TASK_DEF_OLD_ARN" = "null" ]; then
  echo "No existing task definition found for service: $SERVICE_NAME"
  echo "Please create the initial task definition manually in AWS ECS console"
  exit 1
fi

echo "Found existing task definition: $TASK_DEF_OLD_ARN"

#getting old task definition information
TASK_DEF_OLD=$(aws ecs describe-task-definition --task-definition $TASK_DEF_OLD_ARN)

#generating new task definition json
TASK_DEF_NEW=$(echo $TASK_DEF_OLD | jq ' .taskDefinition | .containerDefinitions[].image = "'${REPOSITORY_URI_VERSION}'" | del(.status, .taskDefinitionArn, .requiresAttributes, .compatibilities, .revision, .registeredAt, .registeredBy) ');

#saving to a file
echo $TASK_DEF_NEW > /tmp/$SERVICE_NAME.json

echo "Created new task definition JSON for $SERVICE_NAME"

#creating new task definition
aws ecs register-task-definition --cli-input-json file:///tmp/$SERVICE_NAME.json

#getting new task definition arn
TASK_DEF_NEW_ARN=$(aws ecs list-task-definitions | jq -r ' .taskDefinitionArns[] | select( . | contains("'${SERVICE_NAME}'")) ' | tail -1)

echo "New task definition ARN: $TASK_DEF_NEW_ARN"

#updating service with new task definition
aws ecs update-service \
--cluster $CLUSTER_NAME \
--service $SERVICE_NAME \
--region $REGION \
--task-definition $TASK_DEF_NEW_ARN

echo "Service $SERVICE_NAME updated successfully"
