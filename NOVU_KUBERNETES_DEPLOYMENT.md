# Novu Kubernetes Deployment Guide

This document provides complete instructions for deploying Novu on Kubernetes using the custom Helm chart created from your Docker Compose configuration.

## 📁 Created Files Structure

```
helm/
├── deploy-minikube.sh                    # Automated deployment script
└── novu/                                 # Helm chart
    ├── Chart.yaml                        # Chart metadata
    ├── values.yaml                       # Default configuration values
    ├── README.md                         # Detailed deployment guide
    ├── examples/
    │   └── minikube-values.yaml         # Optimized values for Minikube
    └── templates/
        ├── _helpers.tpl                  # Template helpers
        ├── serviceaccount.yaml           # Service account
        ├── configmap.yaml                # Configuration map
        ├── secret.yaml                   # Secrets management
        ├── redis.yaml                    # Redis StatefulSet & Service
        ├── mongodb.yaml                  # MongoDB StatefulSet & Service
        ├── api.yaml                      # API Deployment & Service
        ├── worker.yaml                   # Worker Deployment
        ├── ws.yaml                       # WebSocket Deployment & Service
        ├── dashboard.yaml                # Dashboard Deployment & Service
        └── ingress.yaml                  # Optional Ingress configuration
```

## 🚀 Quick Start (Automated)

### Option 1: One-Command Deployment

```bash
# Make the script executable and run it
chmod +x helm/deploy-minikube.sh
./helm/deploy-minikube.sh
```

This script will:
- Check prerequisites (Minikube, Helm, kubectl)
- Start Minikube with appropriate resources
- Deploy Novu with optimized settings
- Wait for all pods to be ready
- Display access information

### Script Options

```bash
# Check current status
./helm/deploy-minikube.sh --status

# Clean up deployment
./helm/deploy-minikube.sh --clean

# Show help
./helm/deploy-minikube.sh --help
```

## 🛠 Manual Deployment

### Prerequisites

1. **Install Minikube**
   ```bash
   # macOS
   brew install minikube
   
   # Linux
   curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
   sudo install minikube-linux-amd64 /usr/local/bin/minikube
   ```

2. **Install Helm**
   ```bash
   # macOS
   brew install helm
   
   # Linux
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

3. **Install kubectl** (usually comes with Minikube)

### Step-by-Step Deployment

1. **Start Minikube**
   ```bash
   minikube start --memory=4096 --cpus=4
   ```

2. **Deploy Novu**
   ```bash
   cd helm/novu
   helm install novu . --namespace novu --create-namespace -f examples/minikube-values.yaml
   ```

3. **Wait for Deployment**
   ```bash
   kubectl wait --for=condition=ready pod --all -n novu --timeout=600s
   ```

4. **Get Access Information**
   ```bash
   minikube ip
   # Access dashboard at http://<minikube-ip>:30400
   ```

## 🌐 Accessing Novu Services

### NodePort Access (Default)

After deployment, services are accessible via NodePort:

- **Dashboard**: `http://<minikube-ip>:30400`
- **API**: `http://<minikube-ip>:30300`  
- **WebSocket**: `http://<minikube-ip>:30302`

Get Minikube IP:
```bash
minikube ip
```

### Port Forwarding (Alternative)

```bash
# Dashboard
kubectl port-forward -n novu svc/novu-dashboard 4000:4000
# Access at http://localhost:4000

# API
kubectl port-forward -n novu svc/novu-api 3000:3000
# Access at http://localhost:3000

# WebSocket
kubectl port-forward -n novu svc/novu-ws 3002:3002
# Access at http://localhost:3002
```

## ⚙️ Configuration

### Environment Variables

Key configurations in `values.yaml` and `examples/minikube-values.yaml`:

```yaml
env:
  # Security (Change these!)
  jwtSecret: "your-jwt-secret"
  storeEncryptionKey: "your-encryption-key"
  novuSecretKey: "your-novu-secret"
  
  # Database
  mongoInitdbRootUsername: "admin"
  mongoInitdbRootPassword: "secure-password"
  
  # Service URLs
  viteApiHostname: "http://localhost:30300"
  viteWebsocketHostname: "http://localhost:30302"
```

### Resource Allocation

The Minikube values file includes optimized resource settings:

```yaml
# Example resource configuration
mongodb:
  resources:
    requests: { memory: "256Mi", cpu: "200m" }
    limits: { memory: "512Mi", cpu: "500m" }

api:
  resources:
    requests: { memory: "256Mi", cpu: "200m" }
    limits: { memory: "512Mi", cpu: "500m" }
```

## 🔍 Monitoring and Troubleshooting

### Check Pod Status

```bash
# View all pods
kubectl get pods -n novu

# Watch pods in real-time
kubectl get pods -n novu -w

# Describe a specific pod
kubectl describe pod <pod-name> -n novu
```

### View Logs

```bash
# API logs
kubectl logs -n novu deployment/novu-api -f

# Worker logs
kubectl logs -n novu deployment/novu-worker -f

# Dashboard logs
kubectl logs -n novu deployment/novu-dashboard -f

# MongoDB logs
kubectl logs -n novu statefulset/novu-mongodb -f
```

### Common Issues

1. **Pods stuck in Pending**: Check Minikube resources
   ```bash
   minikube status
   kubectl describe node minikube
   ```

2. **MongoDB connection issues**: Verify MongoDB is ready
   ```bash
   kubectl get pods -n novu | grep mongodb
   kubectl logs -n novu statefulset/novu-mongodb
   ```

3. **Service not accessible**: Check service configuration
   ```bash
   kubectl get svc -n novu
   minikube service list
   ```

## 🏗 Production Considerations

For production deployments, modify the values to:

1. **Use external databases**
   ```yaml
   mongodb:
     enabled: false  # Use external MongoDB
   redis:
     enabled: false  # Use external Redis
   
   env:
     mongoUrl: "mongodb://external-mongo:27017/novu"
     redisHost: "external-redis"
   ```

2. **Configure Ingress**
   ```yaml
   ingress:
     enabled: true
     className: "nginx"
     hosts:
       - host: novu.yourdomain.com
         paths:
           - path: /
             service: dashboard
   ```

3. **Set resource limits**
   ```yaml
   api:
     replicaCount: 3
     resources:
       requests: { memory: "1Gi", cpu: "500m" }
       limits: { memory: "2Gi", cpu: "1000m" }
   ```

## 🧹 Cleanup

### Remove Novu

```bash
helm uninstall novu -n novu
kubectl delete namespace novu
```

### Stop Minikube

```bash
minikube stop
minikube delete
```

## 📋 Default Credentials

When using the Minikube example values:

- **MongoDB**:
  - Username: `novuadmin`
  - Password: `minikubepassword`

⚠️ **Important**: Change these credentials for production use!

## 🔗 Support Resources

- [Novu Documentation](https://docs.novu.co)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)

## 🎯 Next Steps

1. **Access the dashboard** at the provided URL
2. **Create your first notification workflow**
3. **Configure notification providers** (email, SMS, push, etc.)
4. **Integrate with your application** using the Novu SDK
5. **Monitor the system** using the dashboard and logs

---

Your Novu instance is now ready for development and testing on Minikube! 🎉
