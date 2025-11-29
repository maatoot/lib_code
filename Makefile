.PHONY: help build up down logs clean deploy-k8s destroy-k8s tf-init tf-plan tf-apply tf-destroy

help:
	@echo "Library App - Available Commands"
	@echo "================================"
	@echo "Local Development:"
	@echo "  make build          - Build Docker image"
	@echo "  make up             - Start services with docker-compose"
	@echo "  make down           - Stop services"
	@echo "  make logs           - View docker-compose logs"
	@echo ""
	@echo "Terraform:"
	@echo "  make tf-init        - Initialize Terraform"
	@echo "  make tf-plan        - Plan infrastructure changes"
	@echo "  make tf-apply       - Apply infrastructure changes"
	@echo "  make tf-destroy     - Destroy infrastructure"
	@echo ""
	@echo "Kubernetes:"
	@echo "  make deploy-k8s     - Deploy to Kubernetes"
	@echo "  make destroy-k8s    - Destroy Kubernetes resources"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean          - Remove all containers and volumes"

build:
	docker build -t library-app:latest .

up:
	docker-compose up -d

down:
	docker-compose down

logs:
	docker-compose logs -f

clean:
	docker-compose down -v
	docker rmi library-app:latest || true

tf-init:
	cd terraform && terraform init

tf-plan:
	cd terraform && terraform plan

tf-apply:
	cd terraform && terraform apply

tf-destroy:
	cd terraform && terraform destroy

deploy-k8s:
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/secrets.yaml
	kubectl apply -f k8s/redis-deployment.yaml
	kubectl apply -f k8s/web-deployment.yaml
	@echo "Deployment complete. Check status with: kubectl get pods -n library-app"

destroy-k8s:
	kubectl delete namespace library-app

status:
	@echo "=== Docker Compose Status ==="
	docker-compose ps
	@echo ""
	@echo "=== Kubernetes Status ==="
	kubectl get pods -n library-app || echo "Kubernetes not deployed"
