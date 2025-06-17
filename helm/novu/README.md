# Novu Helm Chart

This Helm chart deploys Novu, an open-source notification infrastructure, on Kubernetes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- Minikube (for local development)

## Components

This chart deploys the following components:

- **MongoDB**: Database for storing application data
- **Redis**: Cache and message broker
- **API**: REST API backend service
- **Worker**: Background job processor
- **WebSocket**: Real-time communication service
- **Dashboard**: Web-based frontend interface

## Installation on Minikube

### 1. Install and Start Minikube

```bash
# Install Minikube (if not already installed)
# For macOS
brew install minikube

# For Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube with sufficient resources
minikube start --memory=4096 --cpus=4
```

### 2. Install Helm (if not already installed)

```bash
# For macOS
brew install helm

# For Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 3. Deploy Novu

```bash
# Clone or navigate to the directory containing the Helm chart
cd helm/novu

# Install Novu
helm install novu . --namespace novu --create-namespace

# Or install with custom values
helm install novu . --namespace novu --create-namespace -f your-values.yaml
```

### 4. Wait for Deployment

```bash
# Check the status of all pods
kubectl get pods -n novu

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod --all -n novu --timeout=300s
```

### 5. Access the Dashboard

The dashboard is exposed via NodePort on port 30400:

```bash
# Get Minikube IP
minikube ip

# Access the dashboard at http://<minikube-ip>:30400
# For example: http://192.168.49.2:30400
```

Alternatively, you can use port-forwarding:

```bash
# Port forward the dashboard service
kubectl port-forward -n novu svc/novu-dashboard 4000:4000

# Access at http://localhost:4000
```

## Configuration

### Environment Variables

You can customize the deployment by modifying the `values.yaml` file or creating your own values file:

```yaml
# custom-values.yaml
env:
  jwtSecret: "your-custom-jwt-secret"
  storeEncryptionKey: "your-custom-encryption-key"
  novuSecretKey: "your-custom-novu-secret"
  
  # Database configuration
  mongoInitdbRootUsername: "admin"
  mongoInitdbRootPassword: "your-secure-password"
  
  # API configuration
  viteApiHostname: "http://localhost:3000"
  viteWebsocketHostname: "http://localhost:3002"
```

Then deploy with your custom values:

```bash
helm install novu . -f custom-values.yaml --namespace novu --create-namespace
```

### Resource Configuration

Adjust resource limits and requests based on your cluster capacity:

```yaml
# In values.yaml or custom-values.yaml
api:
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"

mongodb:
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "1000m"
```

### Persistent Storage

MongoDB uses persistent storage by default. You can configure the storage class and size:

```yaml
mongodb:
  persistence:
    enabled: true
    size: 10Gi
    storageClass: "standard"  # Use your cluster's storage class
```

## Useful Commands

### Check Pod Status

```bash
kubectl get pods -n novu -w
```

### View Logs

```bash
# API logs
kubectl logs -n novu deployment/novu-api -f

# Worker logs
kubectl logs -n novu deployment/novu-worker -f

# Dashboard logs
kubectl logs -n novu deployment/novu-dashboard -f
```

### Access Services

```bash
# API service
kubectl port-forward -n novu svc/novu-api 3000:3000

# WebSocket service
kubectl port-forward -n novu svc/novu-ws 3002:3002

# MongoDB (for debugging)
kubectl port-forward -n novu svc/novu-mongodb 27017:27017

# Redis (for debugging)
kubectl port-forward -n novu svc/novu-redis 6379:6379
```

### Scale Services

```bash
# Scale API replicas
kubectl scale deployment novu-api --replicas=3 -n novu

# Scale worker replicas
kubectl scale deployment novu-worker --replicas=2 -n novu
```

## Upgrading

```bash
# Upgrade to a new version
helm upgrade novu . --namespace novu

# Upgrade with new values
helm upgrade novu . --namespace novu -f new-values.yaml
```

## Uninstalling

```bash
# Uninstall the release
helm uninstall novu --namespace novu

# Delete the namespace (this will also delete PVCs)
kubectl delete namespace novu
```

## Troubleshooting

### Common Issues

1. **Pods stuck in Pending state**: Check if Minikube has enough resources
   ```bash
   minikube status
   minikube addons list
   ```

2. **MongoDB connection issues**: Ensure MongoDB is ready before other services
   ```bash
   kubectl get pods -n novu
   kubectl describe pod novu-mongodb-0 -n novu
   ```

3. **Service not accessible**: Check if services are properly exposed
   ```bash
   kubectl get svc -n novu
   ```

### Debug Information

```bash
# Get detailed information about the deployment
helm status novu --namespace novu

# Check Helm values
helm get values novu --namespace novu

# Check events
kubectl get events -n novu --sort-by='.lastTimestamp'
```

## Production Considerations

For production deployments, consider:

1. **Use external databases**: Configure external MongoDB and Redis instances
2. **Enable TLS**: Configure TLS certificates for secure communication
3. **Resource limits**: Set appropriate CPU and memory limits
4. **Monitoring**: Add monitoring and alerting
5. **Backup**: Configure database backups
6. **Ingress**: Use proper ingress controller with domain names
7. **Secrets management**: Use external secrets management (like HashiCorp Vault)

## Support

For issues and questions:
- [Novu Documentation](https://docs.novu.co)
- [GitHub Issues](https://github.com/novuhq/novu/issues)
- [Discord Community](https://discord.novu.co)
