#!/bin/bash

set -euo pipefail

# ********** Local build settings **********
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../Server/MuchToDo"
IMAGE_NAME="starttech-ecr"
IMAGE_TAG="latest"

# ********** AWS / SSM settings **********
AWS_REGION="us-east-1"
SSM_DOCUMENT="AWS-RunShellScript"

# ********** EC2 Instance IDs to deploy to **********
INSTANCE_IDS=("i-0a9b89d419df32115" "i-0e393feaf4294f22b")

# ********** Build and push to AWS ECR **********
echo "Getting AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)

echo "Logging in to AWS ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

ECR_REPO_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Building Docker image for ECR..."
cd "$APP_DIR"
docker build -t "$ECR_REPO_URI/$IMAGE_NAME:$IMAGE_TAG" .

echo "Pushing image to AWS ECR..."
docker push "$ECR_REPO_URI/$IMAGE_NAME:$IMAGE_TAG"


# ********** Read .env file **********
ENV_CONTENT=$(sed 's/"/\\"/g' "$APP_DIR/.env")


# ********** Deploy using SSM **********
for INSTANCE_ID in "${INSTANCE_IDS[@]}"; do
  echo "Deploying to instance $INSTANCE_ID via SSM..."

  aws ssm send-command --no-cli-pager --region "$AWS_REGION" --document-name "$SSM_DOCUMENT" \
    --targets "Key=instanceids,Values=$INSTANCE_ID" \
    --comment "Deploy backend container" \
    --parameters commands="[
      \"set -euo pipefail\",
      \"echo '$ENV_CONTENT' | sudo tee /app/.env\",
      \"aws ecr get-login-password --region $AWS_REGION | sudo docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com\",
      \"sudo docker pull $ECR_REPO_URI/$IMAGE_NAME:$IMAGE_TAG\",
      \"sudo systemctl stop nginx || true\",
      \"sudo docker run -d --name backend_new --restart always -p 80:8080 -v /app/.env:/app/.env \
         -v /app/application.log:/app/application.log $ECR_REPO_URI/$IMAGE_NAME:$IMAGE_TAG\",
      \"sleep 5\",
      \"sudo docker inspect --format='{{.State.Running}}' backend_new\",
      \"sudo docker rm -f backend || true\",
      \"sudo docker rename backend_new backend\"
    ]" \
    --output text
done

echo "Backend application deployed successfully via SSM!"
