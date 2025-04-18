#!/bin/bash
set -e

# Configuration
PROJECT_NAME="chatscomm"
ENVIRONMENT=${ENVIRONMENT:-"dev"}
AWS_REGION=${AWS_REGION:-"us-east-1"}
IMAGE_TAG=${IMAGE_TAG:-"latest"}

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
  exit 1
}

# Parse arguments
MIGRATE=false
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
    -c|--cluster)
      CLUSTER="$2"
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

# Set repository names
WEB_REPO="${PROJECT_NAME}-chatwoot-web-${ENVIRONMENT}"
WORKER_REPO="${PROJECT_NAME}-chatwoot-worker-${ENVIRONMENT}"

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
WEB_REPO_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${WEB_REPO}"
WORKER_REPO_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${WORKER_REPO}"

echo "Building and pushing Chatwoot images to ECR..."
echo "Environment: ${ENVIRONMENT}"
echo "Web Repository: ${WEB_REPO}"
echo "Worker Repository: ${WORKER_REPO}"
echo "Image Tag: ${IMAGE_TAG}"

# Login to ECR
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build and push Web image
echo "Building Chatwoot Web image..."
docker build -t ${WEB_REPO_URL}:${IMAGE_TAG} \
  -f docker/Dockerfile \
  --build-arg RAILS_ENV=production \
  --build-arg RAILS_SERVE_STATIC_FILES=true \
  .

echo "Pushing Chatwoot Web image to ECR..."
docker push ${WEB_REPO_URL}:${IMAGE_TAG}

# Build and push Worker image
echo "Building Chatwoot Worker image..."
docker build -t ${WORKER_REPO_URL}:${IMAGE_TAG} \
  -f docker/Dockerfile \
  --build-arg RAILS_ENV=production \
  --build-arg RAILS_SERVE_STATIC_FILES=true \
  .

echo "Pushing Chatwoot Worker image to ECR..."
docker push ${WORKER_REPO_URL}:${IMAGE_TAG}

# Run migrations if requested
if [ "$MIGRATE" = true ]; then
  echo "Running database migrations..."
  TASK_DEF="${PROJECT_NAME}-chatwoot-migration-task-${ENVIRONMENT}"
  SG_ID=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=${PROJECT_NAME}-chatwoot-${ENVIRONMENT}-sg" --query "SecurityGroups[0].GroupId" --output text --region ${AWS_REGION})
  SUBNET_ID=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=*-private-*" --query "Subnets[0].SubnetId" --output text --region ${AWS_REGION})
  
  aws ecs run-task \
    --cluster ${CLUSTER} \
    --task-definition ${TASK_DEF} \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[${SUBNET_ID}],securityGroups=[${SG_ID}],assignPublicIp=DISABLED}" \
    --region ${AWS_REGION}
    
  echo "Migration task started. Check AWS console for status."
fi

echo "Build and push completed successfully!" 