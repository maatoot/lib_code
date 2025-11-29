# Deployment Guide

## Local Development

```bash
docker-compose up -d
docker-compose logs -f
docker-compose down
```

## AWS Deployment

### Step 1: Prerequisites

```bash
aws configure
```

### Step 2: Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Step 3: Configure kubectl

```bash
aws eks update-kubeconfig --region eu-west-1 --name library-app-cluster
kubectl cluster-info
```

### Step 4: Build and Push Docker Image

```bash
ECR_URL=$(cd terraform && terraform output -raw ecr_repository_url)
docker build -t $ECR_URL:latest .
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $ECR_URL
docker push $ECR_URL:latest
```

### Step 5: Deploy to Kubernetes

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/web-deployment.yaml
```

### Step 6: Access Application

```bash
kubectl get svc library-web -n library-app
# Use the EXTERNAL-IP or hostname
```

## Monitoring

### View Logs

```bash
kubectl logs -n library-app -l app=library-web -f
kubectl logs -n library-app -l app=redis -f
```

### Port Forwarding

```bash
kubectl port-forward -n library-app svc/library-web 8080:80
kubectl port-forward -n library-app svc/redis 6379:6379
```

### Check Status

```bash
kubectl get pods -n library-app
kubectl get svc -n library-app
kubectl get hpa -n library-app
```

## Scaling

### Manual Scaling

```bash
kubectl scale deployment library-web -n library-app --replicas=5
kubectl get deployment library-web -n library-app
```

### Auto-scaling

```bash
kubectl get hpa -n library-app -w
```

## Updating Application

### Update Docker Image

```bash
docker build -t $ECR_URL:v1.1 .
docker push $ECR_URL:v1.1
kubectl set image deployment/library-web library-web=$ECR_URL:v1.1 -n library-app
kubectl rollout status deployment/library-web -n library-app
```

### Rollback

```bash
kubectl rollout history deployment/library-web -n library-app
kubectl rollout undo deployment/library-web -n library-app
kubectl rollout undo deployment/library-web -n library-app --to-revision=2
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

### Pod Not Starting

```bash
kubectl describe pod -n library-app <pod-name>
kubectl logs -n library-app <pod-name>
kubectl get events -n library-app
```

### Redis Connection Issues

```bash
kubectl exec -it -n library-app <web-pod-name> -- redis-cli -h redis ping
kubectl describe pod -n library-app -l app=redis
```

### LoadBalancer Pending

```bash
kubectl describe svc library-web -n library-app
# AWS ELB may take a few minutes to provision
```

### Out of Memory

```bash
kubectl top pods -n library-app
# Increase resource limits in k8s/web-deployment.yaml
kubectl apply -f k8s/web-deployment.yaml
```

## Cost Optimization

### Reduce Node Count

Edit `terraform/terraform.tfvars`:

```hcl
node_group_desired_size = 1
node_group_min_size     = 1
```

Apply changes:

```bash
terraform apply
```

## Security

### Update Secrets

```bash
kubectl edit secret flask-secret -n library-app
kubectl rollout restart deployment/library-web -n library-app
```

### Change Default Credentials

Update admin password in production.

### Enable HTTPS

Install cert-manager and configure ingress with TLS.

## Backup

### Backup Redis Data

```bash
kubectl port-forward -n library-app svc/redis 6379:6379
redis-cli BGSAVE
kubectl cp library-app/<redis-pod>:/data/dump.rdb ./redis-backup.rdb
```

### Restore Redis Data

```bash
kubectl cp ./redis-backup.rdb library-app/<redis-pod>:/data/dump.rdb
kubectl delete pod -n library-app -l app=redis
```
