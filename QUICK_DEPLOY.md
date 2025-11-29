# Quick Deploy Reference

## One-Time Setup

```bash
# 1. Push to Git
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-repo-url>
git push -u origin main

# 2. Deploy Infrastructure
cd terraform
terraform init
terraform plan
terraform apply
cd ..

# 3. Configure kubectl
aws eks update-kubeconfig --region eu-west-1 --name library-app-cluster

# 4. Build and Push Docker Image
ECR_URL=$(cd terraform && terraform output -raw ecr_repository_url)
docker build -t $ECR_URL:latest .
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $ECR_URL
docker push $ECR_URL:latest

# 5. Deploy to Kubernetes
kubectl apply -f k8s/

# 6. Get Service Endpoint
kubectl get svc library-web -n library-app
```

## Access Application

```
URL: http://<EXTERNAL-IP>
Username: superuser1
Password: 123
```

## Common Commands

```bash
# Check status
kubectl get pods -n library-app
kubectl get svc -n library-app

# View logs
kubectl logs -n library-app -l app=library-web -f

# Port forward
kubectl port-forward -n library-app svc/library-web 8080:80

# Scale
kubectl scale deployment library-web -n library-app --replicas=5

# Restart
kubectl rollout restart deployment/library-web -n library-app
```

## Update Application

```bash
# 1. Make code changes
# 2. Commit to Git
git add .
git commit -m "Update description"
git push origin main

# 3. Rebuild Docker image
ECR_URL=$(cd terraform && terraform output -raw ecr_repository_url)
docker build -t $ECR_URL:v1.1 .
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $ECR_URL
docker push $ECR_URL:v1.1

# 4. Update Kubernetes
kubectl set image deployment/library-web library-web=$ECR_URL:v1.1 -n library-app
kubectl rollout status deployment/library-web -n library-app
```

## Cleanup

```bash
# Remove Kubernetes
kubectl delete namespace library-app

# Destroy Infrastructure
cd terraform
terraform destroy
```

## Terraform Outputs

```bash
# Get ECR URL
terraform output -raw ecr_repository_url

# Get EKS endpoint
terraform output -raw eks_cluster_endpoint

# Get cluster name
terraform output -raw eks_cluster_name

# Get VPC ID
terraform output -raw vpc_id

# Get kubectl config command
terraform output -raw configure_kubectl
```

## Troubleshooting

```bash
# Check admin user creation
kubectl logs -n library-app -l app=library-web | grep "Admin user"

# Test Redis
kubectl exec -it -n library-app <pod> -- redis-cli -h redis ping

# Check pod details
kubectl describe pod -n library-app <pod-name>

# Check events
kubectl get events -n library-app
```

## Default Credentials

- Username: `superuser1`
- Password: `123`

⚠️ Change after first login!
