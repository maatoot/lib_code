# Deploy with Git + Terraform

## Overview

This guide covers deploying the Library App using Git for version control and Terraform for infrastructure.

## Prerequisites

- Git installed
- AWS Account with credentials configured
- Terraform installed
- kubectl installed
- Docker installed

## Step 1: Push Code to Git

```bash
# Initialize Git repository
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Library App with Docker, Kubernetes, and Terraform"

# Add remote repository
git remote add origin https://github.com/your-username/library-app.git

# Push to main branch
git branch -M main
git push -u origin main
```

## Step 2: Deploy Infrastructure with Terraform

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

**Output will include:**
- EKS cluster endpoint
- ECR repository URL
- VPC ID
- Configure kubectl command

## Step 3: Configure kubectl

```bash
# Use the output from terraform apply
aws eks update-kubeconfig --region eu-west-1 --name library-app-cluster

# Verify connection
kubectl cluster-info
```

## Step 4: Build and Push Docker Image

```bash
# Get ECR repository URL from terraform output
ECR_URL=$(terraform output -raw ecr_repository_url)

# Build Docker image
docker build -t $ECR_URL:latest ..

# Login to ECR
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $ECR_URL

# Push image to ECR
docker push $ECR_URL:latest
```

## Step 5: Deploy to Kubernetes

```bash
# Navigate back to root
cd ..

# Create namespace
kubectl apply -f k8s/namespace.yaml

# Create secrets
kubectl apply -f k8s/secrets.yaml

# Deploy Redis
kubectl apply -f k8s/redis-deployment.yaml

# Deploy web application
kubectl apply -f k8s/web-deployment.yaml

# Verify deployment
kubectl get pods -n library-app
```

## Step 6: Access the Application

```bash
# Get the LoadBalancer endpoint
kubectl get svc library-web -n library-app

# Copy the EXTERNAL-IP or hostname and access in browser
# http://<EXTERNAL-IP>

# Login with:
# Username: superuser1
# Password: 123
```

## Verify Admin User Creation

```bash
# Check logs for admin user creation
kubectl logs -n library-app -l app=library-web -f

# Look for: "Admin user created: superuser1/123"
```

## Update Application (After Code Changes)

### 1. Commit Changes to Git

```bash
git add .
git commit -m "Description of changes"
git push origin main
```

### 2. Rebuild and Push Docker Image

```bash
cd terraform
ECR_URL=$(terraform output -raw ecr_repository_url)
cd ..

docker build -t $ECR_URL:v1.1 .
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $ECR_URL
docker push $ECR_URL:v1.1
```

### 3. Update Kubernetes Deployment

```bash
kubectl set image deployment/library-web library-web=$ECR_URL:v1.1 -n library-app
kubectl rollout status deployment/library-web -n library-app
```

## Monitoring

### View Logs

```bash
# Web application logs
kubectl logs -n library-app -l app=library-web -f

# Redis logs
kubectl logs -n library-app -l app=redis -f
```

### Check Status

```bash
# Pod status
kubectl get pods -n library-app

# Service status
kubectl get svc -n library-app

# Deployment status
kubectl get deployment -n library-app

# Auto-scaling status
kubectl get hpa -n library-app
```

### Port Forwarding

```bash
# Access web app locally
kubectl port-forward -n library-app svc/library-web 8080:80

# Access Redis locally
kubectl port-forward -n library-app svc/redis 6379:6379
```

## Scaling

### Manual Scaling

```bash
# Scale to 5 replicas
kubectl scale deployment library-web -n library-app --replicas=5

# Check current replicas
kubectl get deployment library-web -n library-app
```

### Auto-scaling

```bash
# View HPA status
kubectl get hpa -n library-app -w

# Configured to scale 2-5 replicas based on CPU/Memory
```

## Cleanup

### Remove Kubernetes Resources

```bash
kubectl delete namespace library-app
```

### Destroy Infrastructure

```bash
cd terraform
terraform destroy
```

## Troubleshooting

### Admin User Not Created

```bash
# Check logs
kubectl logs -n library-app -l app=library-web

# Restart pods
kubectl rollout restart deployment/library-web -n library-app
```

### Redis Connection Issues

```bash
# Test Redis connection
kubectl exec -it -n library-app <web-pod> -- redis-cli -h redis ping

# Should return: PONG
```

### Pod Not Starting

```bash
# Check pod details
kubectl describe pod -n library-app <pod-name>

# Check events
kubectl get events -n library-app
```

### LoadBalancer Pending

```bash
# Check service status
kubectl describe svc library-web -n library-app

# AWS ELB may take a few minutes to provision
```

## Quick Commands

```bash
# Full deployment
cd terraform && terraform init && terraform apply && cd ..
aws eks update-kubeconfig --region eu-west-1 --name library-app-cluster
ECR_URL=$(cd terraform && terraform output -raw ecr_repository_url)
docker build -t $ECR_URL:latest .
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $ECR_URL
docker push $ECR_URL:latest
kubectl apply -f k8s/

# Check status
kubectl get pods -n library-app
kubectl get svc library-web -n library-app
```

## Environment Variables

Update `k8s/secrets.yaml` for production:

```yaml
stringData:
  secret-key: "your-secure-random-key"
```

## Security Notes

- Change default admin password after first login
- Update Flask secret key in secrets.yaml
- Use AWS Secrets Manager for sensitive data
- Enable HTTPS/TLS in production
- Restrict security group access

## Cost Optimization

- Current setup uses t3.small instances (cost-effective)
- Auto-scaling configured (scales down when not needed)
- Estimated monthly cost: $100-150

To reduce costs:
- Use 1 node instead of 2
- Use spot instances
- Schedule scaling down during off-hours

## Support

Refer to:
- README.md - Project overview
- QUICKSTART.md - Quick commands
- TROUBLESHOOT.md - Troubleshooting guide
