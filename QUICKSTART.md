# Quick Start

## Local Development (5 minutes)

```bash
docker-compose up -d
# http://localhost:5001
# Login: superuser1 / 123
```

## AWS Deployment (30 minutes)

```bash
# Configure AWS
aws configure

# Deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# Configure kubectl
aws eks update-kubeconfig --region eu-west-1 --name library-app-cluster

# Build and push Docker image
ECR_URL=$(terraform output -raw ecr_repository_url)
docker build -t $ECR_URL:latest ..
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $ECR_URL
docker push $ECR_URL:latest

# Deploy to Kubernetes
cd ..
kubectl apply -f k8s/

# Get service endpoint
kubectl get svc library-web -n library-app
```

## Common Commands

### Docker Compose

```bash
make up              # Start services
make logs            # View logs
make down            # Stop services
make clean           # Full cleanup
```

### Terraform

```bash
make tf-init         # Initialize
make tf-plan         # Plan changes
make tf-apply        # Deploy
make tf-destroy      # Destroy
```

### Kubernetes

```bash
kubectl get pods -n library-app
kubectl logs -n library-app -l app=library-web -f
kubectl port-forward -n library-app svc/library-web 8080:80
kubectl scale deployment library-web -n library-app --replicas=5
```

## Troubleshooting

### Docker Issues

```bash
docker-compose logs
docker-compose restart
docker-compose down -v && docker-compose up -d
```

### Kubernetes Issues

```bash
kubectl describe pod -n library-app <pod-name>
kubectl logs -n library-app <pod-name>
kubectl get events -n library-app
```

### Terraform Issues

```bash
terraform validate
terraform state list
terraform refresh
```

## Default Credentials

- Username: `superuser1`
- Password: `123`
