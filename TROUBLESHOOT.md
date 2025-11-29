# Troubleshooting - Login Not Working

## Issue
Login page appears but credentials (superuser1/123) don't work.

## Root Cause
The admin user initialization only happens when the app starts. In Kubernetes with Gunicorn, the initialization wasn't running.

## Solution

### Step 1: Update the Code
The app.py has been updated to initialize the admin user on startup. The fix is already applied.

### Step 2: Rebuild and Push Docker Image

```bash
# Build image
docker build -t 617835328146.dkr.ecr.eu-west-1.amazonaws.com/library-app:latest .

# Login to ECR
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 617835328146.dkr.ecr.eu-west-1.amazonaws.com

# Push image
docker push 617835328146.dkr.ecr.eu-west-1.amazonaws.com/library-app:latest
```

Or use the script:
```bash
chmod +x scripts/update-image.sh
./scripts/update-image.sh
```

### Step 3: Update Kubernetes Deployment

```bash
kubectl set image deployment/library-web library-web=617835328146.dkr.ecr.eu-west-1.amazonaws.com/library-app:latest -n library-app
```

### Step 4: Wait for Rollout

```bash
kubectl rollout status deployment/library-web -n library-app
```

### Step 5: Test Login

```bash
# Get service endpoint
kubectl get svc library-web -n library-app

# Access the app and login with:
# Username: superuser1
# Password: 123
```

## Verify Admin User Creation

### Check Logs
```bash
kubectl logs -n library-app -l app=library-web -f
```

Look for: `Admin user created: superuser1/123`

### Check Redis Data
```bash
# Port forward Redis
kubectl port-forward -n library-app svc/redis 6379:6379

# In another terminal
redis-cli
> GET users
```

You should see the admin user in the JSON data.

### Health Check
```bash
# Get service endpoint
SERVICE_IP=$(kubectl get svc library-web -n library-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test health endpoint
curl http://$SERVICE_IP/health
```

Should return: `{"status":"healthy"}`

## If Still Not Working

### 1. Check Pod Status
```bash
kubectl describe pod -n library-app -l app=library-web
```

### 2. Check Events
```bash
kubectl get events -n library-app
```

### 3. Check Redis Connection
```bash
kubectl exec -it -n library-app <web-pod-name> -- redis-cli -h redis ping
```

Should return: `PONG`

### 4. Restart Pods
```bash
kubectl rollout restart deployment/library-web -n library-app
kubectl rollout restart deployment/redis -n library-app
```

### 5. Check Secrets
```bash
kubectl get secret flask-secret -n library-app -o yaml
```

## Manual Admin Creation

If needed, you can manually create the admin user:

```bash
# Port forward Redis
kubectl port-forward -n library-app svc/redis 6379:6379

# In another terminal, connect to Redis
redis-cli

# Create admin user (replace HASH with actual hash)
> SET users '[{"username":"superuser1","password":"HASH","role":"admin"}]'

# Verify
> GET users
```

To generate the password hash:
```python
from werkzeug.security import generate_password_hash
print(generate_password_hash("123"))
```

## Quick Commands

```bash
# Build and push
docker build -t 617835328146.dkr.ecr.eu-west-1.amazonaws.com/library-app:latest . && \
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 617835328146.dkr.ecr.eu-west-1.amazonaws.com && \
docker push 617835328146.dkr.ecr.eu-west-1.amazonaws.com/library-app:latest

# Update deployment
kubectl set image deployment/library-web library-web=617835328146.dkr.ecr.eu-west-1.amazonaws.com/library-app:latest -n library-app

# Check status
kubectl rollout status deployment/library-web -n library-app

# View logs
kubectl logs -n library-app -l app=library-web -f

# Get service endpoint
kubectl get svc library-web -n library-app
```

## Default Credentials

- Username: `superuser1`
- Password: `123`

These are created automatically on first app startup.
