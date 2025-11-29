#!/bin/bash

set -e

ECR_URL="617835328146.dkr.ecr.eu-west-1.amazonaws.com/library-app"
REGION="eu-west-1"

echo "=== Updating Docker Image ==="
echo ""

# Build image
echo "1. Building Docker image..."
docker build -t $ECR_URL:latest .

# Login to ECR
echo ""
echo "2. Logging in to ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

# Push image
echo ""
echo "3. Pushing image to ECR..."
docker push $ECR_URL:latest

# Update deployment
echo ""
echo "4. Updating Kubernetes deployment..."
kubectl set image deployment/library-web library-web=$ECR_URL:latest -n library-app

# Check status
echo ""
echo "5. Checking rollout status..."
kubectl rollout status deployment/library-web -n library-app

echo ""
echo "✅ Update complete!"
