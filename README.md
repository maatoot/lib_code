# Library App - Flask + Redis + Kubernetes + Terraform

A production-ready library management application with book borrowing functionality, built with Flask and Redis, containerized with Docker, and deployable to AWS EKS using Terraform.

## Features

- User authentication (signup/login)
- Admin role for book management
- Book borrowing and returning system
- Search functionality
- Redis for data persistence
- Kubernetes deployment with auto-scaling
- AWS EKS infrastructure via Terraform

## Quick Start - Local Development

```bash
# Start services
docker-compose up -d

# Access the app
# http://localhost:5001

# Default credentials
# Username: superuser1
# Password: 123

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## Quick Start - AWS Deployment

```bash
# 1. Configure AWS
aws configure

# 2. Deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# 3. Configure kubectl
aws eks update-kubeconfig --region eu-west-1 --name library-app-cluster

# 4. Build and push Docker image
ECR_URL=$(terraform output -raw ecr_repository_url)
docker build -t $ECR_URL:latest ..
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $ECR_URL
docker push $ECR_URL:latest

# 5. Deploy to Kubernetes
cd ..
kubectl apply -f k8s/

# 6. Get service endpoint
kubectl get svc library-web -n library-app
```

## Make Commands

```bash
# Local Development
make up              # Start services
make down            # Stop services
make logs            # View logs
make clean           # Full cleanup

# Terraform
make tf-init         # Initialize Terraform
make tf-plan         # Plan changes
make tf-apply        # Deploy infrastructure
make tf-destroy      # Destroy infrastructure

# Kubernetes
make deploy-k8s      # Deploy to Kubernetes
make destroy-k8s     # Destroy Kubernetes resources
make status          # Check status
```

## Kubernetes Commands

```bash
# Check deployment status
kubectl get pods -n library-app
kubectl get svc -n library-app
kubectl get hpa -n library-app

# View logs
kubectl logs -n library-app -l app=library-web -f
kubectl logs -n library-app -l app=redis -f

# Port forwarding
kubectl port-forward -n library-app svc/library-web 8080:80
kubectl port-forward -n library-app svc/redis 6379:6379

# Describe resources
kubectl describe pod -n library-app <pod-name>
kubectl describe svc -n library-app library-web

# Scale deployment
kubectl scale deployment library-web -n library-app --replicas=5

# Restart deployment
kubectl rollout restart deployment/library-web -n library-app
```


Edit with your values:

```
FLASK_SECRET_KEY=your-secret-key
REDIS_HOST=redis
REDIS_PORT=6379
FLASK_DEBUG=false
```

### Terraform Variables

Edit `terraform/terraform.tfvars`:

```hcl
aws_region              = "eu-west-1"
instance_types          = ["t3.small"]
node_group_desired_size = 2
```

### Kubernetes Secrets

Edit `k8s/secrets.yaml`:

```yaml
stringData:
  secret-key: "your-secure-key"
```


### Docker Compose Issues

```bash
# Check logs
docker-compose logs

# Restart services
docker-compose restart

# Full reset
docker-compose down -v
docker-compose up -d
```

### Kubernetes Issues

```bash
# Check pod status
kubectl describe pod -n library-app <pod-name>

# Check events
kubectl get events -n library-app

# Check logs
kubectl logs -n library-app <pod-name>

# Restart deployment
kubectl rollout restart deployment/library-web -n library-app
```

### Terraform Issues

```bash
# Validate configuration
terraform validate

# Check state
terraform state list

# Refresh state
terraform refresh

# Destroy and retry
terraform destroy
terraform apply
```

## Cleanup

### Local

```bash
docker-compose down -v
```

### AWS

```bash
cd terraform
terraform destroy
```
