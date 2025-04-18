#!/bin/bash
set -e

# Configuration
PROJECT_NAME="chatscomm"
ENVIRONMENT=${ENVIRONMENT:-"dev"}
AWS_REGION=${AWS_REGION:-"us-east-1"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}
AWS_PROFILE=${AWS_PROFILE:-"chatscomm"}

# Print usage
usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -h, --help          Show this help message and exit"
  echo "  -e, --environment   Environment (dev, staging, prod) [default: dev]"
  echo "  -r, --region        AWS region [default: us-east-1]"
  echo "  -t, --tag           Image tag [default: latest]"
  echo "  -m, --migrate       Run database migrations after pushing images"
  echo "  -c, --cluster       ECS cluster name (required for migrations)"
  echo "  -p, --profile       AWS profile [default: chatscomm]"
  echo "  --migrate-only      Run only migrations without building/pushing images"
  echo "  --connect           Connect to a running web container for interactive commands"
  echo "  --exec-migrate      Execute migrations directly in running container (recommended)"
  exit 1
}

# Parse arguments
MIGRATE=false
MIGRATE_ONLY=false
CONNECT=false
EXEC_MIGRATE=false
CLUSTER=""

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help)
      usage
      ;;
    -e|--environment)
      ENVIRONMENT="$2"
      shift
      shift
      ;;
    -r|--region)
      AWS_REGION="$2"
      shift
      shift
      ;;
    -t|--tag)
      IMAGE_TAG="$2"
      shift
      shift
      ;;
    -m|--migrate)
      MIGRATE=true
      shift
      ;;
    --migrate-only)
      MIGRATE_ONLY=true
      MIGRATE=true
      shift
      ;;
    --connect)
      CONNECT=true
      shift
      ;;
    --exec-migrate)
      EXEC_MIGRATE=true
      shift
      ;;
    -c|--cluster)
      CLUSTER="$2"
      shift
      shift
      ;;
    -p|--profile)
      AWS_PROFILE="$2"
      shift
      shift
      ;;
    *)
      echo "Unknown option: $1"
      usage
      ;;
  esac
done

# Validate
if [ "$MIGRATE" = true ] && [ -z "$CLUSTER" ]; then
  echo "Error: ECS cluster name is required for migrations"
  usage
fi

if [ "$CONNECT" = true ] && [ -z "$CLUSTER" ]; then
  echo "Error: ECS cluster name is required for connecting to a container"
  usage
fi

if [ "$EXEC_MIGRATE" = true ] && [ -z "$CLUSTER" ]; then
  echo "Error: ECS cluster name is required for executing migrations"
  usage
fi

# Set repository names
WEB_REPO="${PROJECT_NAME}-chatwoot-web-${ENVIRONMENT}"
WORKER_REPO="${PROJECT_NAME}-chatwoot-worker-${ENVIRONMENT}"

# Hardcoded AWS account ID
AWS_ACCOUNT_ID="008971651719"
# Force string handling by adding quotes
WEB_REPO_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${WEB_REPO}"
WORKER_REPO_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${WORKER_REPO}"

# Execute migrations in a running container
if [ "$EXEC_MIGRATE" = true ]; then
  echo "Executing migrations in a running container..."
  
  # Get the task ID of a running web task
  TASK_ID=$(aws ecs list-tasks \
    --cluster ${CLUSTER} \
    --family "${PROJECT_NAME}-chatwoot-${ENVIRONMENT}-web-task" \
    --desired-status RUNNING \
    --region ${AWS_REGION} \
    --profile ${AWS_PROFILE} \
    --query 'taskArns[0]' --output text | awk -F '/' '{print $NF}')
  
  if [ -z "$TASK_ID" ] || [ "$TASK_ID" = "None" ]; then
    echo "No running tasks found. Please make sure there's at least one running web task."
    exit 1
  fi
  
  echo "Found running task: ${TASK_ID}"
  CONTAINER_NAME="${PROJECT_NAME}-chatwoot-${ENVIRONMENT}-web-container"
  
  echo "Executing migrations in container ${CONTAINER_NAME}..."
  
  # Check if SSM plugin is installed
  if ! command -v session-manager-plugin &> /dev/null; then
    echo "AWS Session Manager Plugin is not installed. Migrations can't be executed directly."
    echo "Please install the Session Manager Plugin: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"
    echo ""
    echo "As an alternative, please go to the AWS Console:"
    echo "1. Navigate to ECS > Clusters > ${CLUSTER}"
    echo "2. Select the tasks tab and find task ${TASK_ID}"
    echo "3. Click on the task and then the 'Execute Command' button"
    echo "4. Select container '${CONTAINER_NAME}'"
    echo "5. Use command: /bin/bash -c 'cd /app && bundle exec rails db:migrate'"
    exit 1
  fi
  
  # Use ECS Exec to run migrations
  echo "Running migrations..."
  aws ecs execute-command \
    --cluster ${CLUSTER} \
    --task ${TASK_ID} \
    --container ${CONTAINER_NAME} \
    --command "/bin/sh" \
    --interactive \
    --region ${AWS_REGION} \
    --profile ${AWS_PROFILE}
    
  echo "Migration command executed."
  exit 0
fi

# Connect to a running container
if [ "$CONNECT" = true ]; then
  echo "Connecting to a running Chatwoot web container..."
  
  # Get the task ID of a running web task
  TASK_ID=$(aws ecs list-tasks \
    --cluster ${CLUSTER} \
    --family chatscomm-chatwoot-${ENVIRONMENT}-web-task \
    --region ${AWS_REGION} \
    --profile ${AWS_PROFILE} \
    --query 'taskArns[0]' --output text | awk -F '/' '{print $NF}')
  
  if [ -z "$TASK_ID" ] || [ "$TASK_ID" = "None" ]; then
    echo "No running tasks found. Starting a new task..."
    
    # Get subnet and security group
    SG_ID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=${PROJECT_NAME}-chatwoot-${ENVIRONMENT}-sg" --query "SecurityGroups[0].GroupId" --output text --region ${AWS_REGION} --profile ${AWS_PROFILE})
    SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=*-private-*" --query "Subnets[0].SubnetId" --output text --region ${AWS_REGION} --profile ${AWS_PROFILE})
    
    # Start a new task
    TASK_ARN=$(aws ecs run-task \
      --cluster ${CLUSTER} \
      --task-definition ${PROJECT_NAME}-chatwoot-${ENVIRONMENT}-web-task \
      --launch-type FARGATE \
      --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_ID}],securityGroups=[${SG_ID}],assignPublicIp=DISABLED}" \
      --region ${AWS_REGION} \
      --profile ${AWS_PROFILE} \
      --query 'tasks[0].taskArn' \
      --output text)
    
    TASK_ID=$(echo $TASK_ARN | awk -F '/' '{print $NF}')
    
    echo "New task started with ID: ${TASK_ID}"
    echo "Waiting for task to start..."
    
    # Wait for the task to start
    aws ecs wait tasks-running \
      --cluster ${CLUSTER} \
      --tasks ${TASK_ARN} \
      --region ${AWS_REGION} \
      --profile ${AWS_PROFILE}
  fi
  
  echo "Connecting to task ${TASK_ID}..."
  CONTAINER_NAME="${PROJECT_NAME}-chatwoot-${ENVIRONMENT}-web-container"
  
  # Connect using ECS exec
  aws ecs execute-command \
    --cluster ${CLUSTER} \
    --task ${TASK_ID} \
    --container ${CONTAINER_NAME} \
    --interactive \
    --command "/bin/bash" \
    --region ${AWS_REGION} \
    --profile ${AWS_PROFILE}
  
  exit 0
fi

# Skip build/push if migrate-only is set
if [ "$MIGRATE_ONLY" = false ]; then
  echo "Building and pushing Chatwoot images to ECR..."
  echo "Environment: ${ENVIRONMENT}"
  echo "AWS Account ID: ${AWS_ACCOUNT_ID}"
  echo "AWS Profile: ${AWS_PROFILE}"
  echo "Web Repository: ${WEB_REPO}"
  echo "Worker Repository: ${WORKER_REPO}"
  echo "Image Tag: ${IMAGE_TAG}"

  # Login to ECR - explicitly use the hardcoded account ID
  echo "Logging in to Amazon ECR..."
  aws ecr get-login-password --region ${AWS_REGION} --profile ${AWS_PROFILE} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

  # Build and push Web image
  echo "Building Chatwoot Web image..."
  docker build -t ${WEB_REPO_URL}:${IMAGE_TAG} \
    -f docker/Dockerfile \
    --platform linux/amd64 \
    --build-arg RAILS_ENV=production \
    --build-arg RAILS_SERVE_STATIC_FILES=true \
    .

  echo "Pushing Chatwoot Web image to ECR..."
  docker push ${WEB_REPO_URL}:${IMAGE_TAG}

  # Build and push Worker image
  echo "Building Chatwoot Worker image..."
  docker build -t ${WORKER_REPO_URL}:${IMAGE_TAG} \
    -f docker/Dockerfile \
    --platform linux/amd64 \
    --build-arg RAILS_ENV=production \
    --build-arg RAILS_SERVE_STATIC_FILES=true \
    .

  echo "Pushing Chatwoot Worker image to ECR..."
  docker push ${WORKER_REPO_URL}:${IMAGE_TAG}
fi

# Run migrations if requested
if [ "$MIGRATE" = true ]; then
  echo "Running database migrations..."
  TASK_DEF="${PROJECT_NAME}-chatwoot-${ENVIRONMENT}-web-task"
  SG_ID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=${PROJECT_NAME}-chatwoot-${ENVIRONMENT}-sg" --query "SecurityGroups[0].GroupId" --output text --region ${AWS_REGION} --profile ${AWS_PROFILE})
  SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=*-private-*" --query "Subnets[0].SubnetId" --output text --region ${AWS_REGION} --profile ${AWS_PROFILE})
  
  CONTAINER_NAME="${PROJECT_NAME}-chatwoot-${ENVIRONMENT}-web-container"
  
  # Use a simple test command first
  COMMAND_OVERRIDE='{
    "containerOverrides": [
      {
        "name": "'${CONTAINER_NAME}'",
        "command": ["echo", "MIGRATION TEST COMMAND"]
      }
    ]
  }'
  
  echo "Starting migration task with command override:"
  echo "${COMMAND_OVERRIDE}"
  
  # Run the task and capture the task ARN
  TASK_ARN=$(aws ecs run-task \
    --cluster ${CLUSTER} \
    --task-definition ${TASK_DEF} \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_ID}],securityGroups=[${SG_ID}],assignPublicIp=DISABLED}" \
    --overrides "${COMMAND_OVERRIDE}" \
    --region ${AWS_REGION} \
    --profile ${AWS_PROFILE} \
    --query 'tasks[0].taskArn' \
    --output text)
  
  echo "Migration task started with ARN: ${TASK_ARN}"
  echo "Waiting for migration task to complete..."
  
  # Extract the task ID from the ARN
  TASK_ID=$(echo $TASK_ARN | awk -F '/' '{print $NF}')
  
  # Wait for the task to complete (either succeeded or failed)
  while true; do
    TASK_STATUS=$(aws ecs describe-tasks \
      --cluster ${CLUSTER} \
      --tasks ${TASK_ARN} \
      --region ${AWS_REGION} \
      --profile ${AWS_PROFILE} \
      --query 'tasks[0].lastStatus' \
      --output text)
    
    if [ "$TASK_STATUS" = "STOPPED" ]; then
      break
    fi
    
    echo "Task is ${TASK_STATUS}... waiting 10 seconds"
    sleep 10
  done
  
  # Get the exit code
  EXIT_CODE=$(aws ecs describe-tasks \
    --cluster ${CLUSTER} \
    --tasks ${TASK_ARN} \
    --region ${AWS_REGION} \
    --profile ${AWS_PROFILE} \
    --query 'tasks[0].containers[0].exitCode' \
    --output text)
  
  if [ "$EXIT_CODE" = "0" ]; then
    echo "Migration completed successfully!"
  else
    echo "Migration failed with exit code ${EXIT_CODE}"
    
    # Get the log stream name
    LOG_STREAM_NAME="ecs/chatscomm-chatwoot-dev-web-container/${TASK_ID}"
    
    echo "Check the logs for details:"
    echo "Log group: /aws/ecs/${PROJECT_NAME}-chatwoot-${ENVIRONMENT}-web"
    echo "Log stream: ${LOG_STREAM_NAME}"
    
    # Show recent logs
    echo "Recent logs (if available):"
    aws logs get-log-events \
      --log-group-name "/aws/ecs/${PROJECT_NAME}-chatwoot-${ENVIRONMENT}-web" \
      --log-stream-name ${LOG_STREAM_NAME} \
      --limit 20 \
      --region ${AWS_REGION} \
      --profile ${AWS_PROFILE} \
      --query 'events[*].[message]' \
      --output text || echo "Logs not available yet. Check in AWS Console."
    
    if [ "$MIGRATE_ONLY" = true ]; then
      exit 1
    fi
  fi
fi

if [ "$MIGRATE_ONLY" = false ]; then
  echo "Build and push completed successfully!"
else
  echo "Migration command executed successfully!"
fi 