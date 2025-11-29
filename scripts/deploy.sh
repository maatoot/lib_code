#!/bin/bash

set -e

echo "=== Library App Deployment Script ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Terraform not found. Please install Terraform.${NC}"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}kubectl not found. Please install kubectl.${NC}"
        exit 1
    fi
    
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}AWS CLI not found. Please install AWS CLI.${NC}"
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker not found. Please install Docker.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All prerequisites found.${NC}"
    echo ""
}

# Deploy infrastructure
deploy_infrastructure() {
    echo -e "${YELLOW}Deploying infrastructure with Terraform...${NC}"
    
    cd terraform
    terraform init
    terraform plan -out=tfplan
    terraform apply tfplan
    
    echo -e "${GREEN}Infrastructure deployed successfully.${NC}"
    echo ""
    
    cd ..
}

# Configure kubectl
configure_kubectl() {
    echo -e "${YELLOW}Configuring kubectl...${NC}"
    
    CLUSTER_NAME=$(cd terraform && terraform output -raw eks_cluster_name)
    REGION=$(cd terraform && terraform output -raw eks_cluster_endpoint | grep -oP 'https://[^.]+' | sed 's/https:\/\///' | awk -F. '{print $(NF-2)}')
    
    aws eks update-kubeconfig --region eu-west-1 --name $CLUSTER_NAME
    
    echo -e "${GREEN}kubectl configured.${NC}"
    echo ""
}

# Build and push Docker image
build_and_push_image() {
    echo -e "${YELLOW}Building and pushing Docker image...${NC}"
    
    ECR_URL=$(cd terraform && terraform output -raw ecr_repository_url)
    
    docker build -t $ECR_URL:latest .
    
    aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $ECR_URL
    docker push $ECR_URL:latest
    
    echo -e "${GREEN}Docker image pushed to ECR.${NC}"
    echo ""
}

# Deploy to Kubernetes
deploy_to_kubernetes() {
    echo -e "${YELLOW}Deploying to Kubernetes...${NC}"
    
    kubectl apply -f k8s/namespace.yaml
    kubectl apply -f k8s/secrets.yaml
    kubectl apply -f k8s/redis-deployment.yaml
    kubectl apply -f k8s/web-deployment.yaml
    
    echo -e "${GREEN}Kubernetes deployment complete.${NC}"
    echo ""
}

# Wait for deployment
wait_for_deployment() {
    echo -e "${YELLOW}Waiting for deployment to be ready...${NC}"
    
    kubectl wait --for=condition=available --timeout=300s deployment/library-web -n library-app
    
    echo -e "${GREEN}Deployment is ready.${NC}"
    echo ""
}

# Get service endpoint
get_service_endpoint() {
    echo -e "${YELLOW}Getting service endpoint...${NC}"
    
    SERVICE_IP=$(kubectl get svc library-web -n library-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    if [ -z "$SERVICE_IP" ]; then
        SERVICE_IP=$(kubectl get svc library-web -n library-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    fi
    
    echo -e "${GREEN}Service endpoint: http://$SERVICE_IP${NC}"
    echo ""
}

# Main execution
main() {
    check_prerequisites
    deploy_infrastructure
    configure_kubectl
    build_and_push_image
    deploy_to_kubernetes
    wait_for_deployment
    get_service_endpoint
    
    echo -e "${GREEN}=== Deployment Complete ===${NC}"
}

main
