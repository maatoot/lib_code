#!/bin/bash

set -e

echo "=== Library App Cleanup Script ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Confirm before cleanup
confirm() {
    local prompt="$1"
    local response
    
    read -p "$(echo -e ${YELLOW}$prompt${NC})" response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Cleanup Kubernetes
cleanup_kubernetes() {
    echo -e "${YELLOW}Cleaning up Kubernetes resources...${NC}"
    
    if kubectl get namespace library-app &> /dev/null; then
        kubectl delete namespace library-app
        echo -e "${GREEN}Kubernetes resources deleted.${NC}"
    else
        echo -e "${YELLOW}Kubernetes namespace not found.${NC}"
    fi
    echo ""
}

# Cleanup Terraform
cleanup_terraform() {
    echo -e "${YELLOW}Destroying infrastructure with Terraform...${NC}"
    
    cd terraform
    terraform destroy
    cd ..
    
    echo -e "${GREEN}Infrastructure destroyed.${NC}"
    echo ""
}

# Cleanup Docker
cleanup_docker() {
    echo -e "${YELLOW}Cleaning up Docker resources...${NC}"
    
    docker-compose down -v
    docker rmi library-app:latest || true
    
    echo -e "${GREEN}Docker resources cleaned up.${NC}"
    echo ""
}

# Main execution
main() {
    if confirm "This will delete all Kubernetes resources. Continue? (y/n) "; then
        cleanup_kubernetes
    fi
    
    if confirm "This will destroy all AWS infrastructure. Continue? (y/n) "; then
        cleanup_terraform
    fi
    
    if confirm "This will remove local Docker resources. Continue? (y/n) "; then
        cleanup_docker
    fi
    
    echo -e "${GREEN}=== Cleanup Complete ===${NC}"
}

main
