#!/bin/bash

# Novu Minikube Deployment Script
# This script automates the deployment of Novu on Minikube

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command_exists minikube; then
        print_error "Minikube is not installed. Please install it first."
        echo "For macOS: brew install minikube"
        echo "For Linux: curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube"
        exit 1
    fi
    
    if ! command_exists helm; then
        print_error "Helm is not installed. Please install it first."
        echo "For macOS: brew install helm"
        echo "For Linux: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
        exit 1
    fi
    
    if ! command_exists kubectl; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
    
    print_success "All prerequisites are installed"
}

# Start Minikube
start_minikube() {
    print_info "Checking Minikube status..."
    
    if minikube status >/dev/null 2>&1; then
        print_success "Minikube is already running"
    else
        print_info "Starting Minikube with 4GB RAM and 4 CPUs..."
        minikube start --memory=4096 --cpus=4
        print_success "Minikube started successfully"
    fi
    
    # Wait for Minikube to be ready
    print_info "Waiting for Minikube to be ready..."
    kubectl wait --for=condition=ready node --all --timeout=300s
}

# Deploy Novu
deploy_novu() {
    print_info "Deploying Novu to Kubernetes..."
    
    # Navigate to the helm chart directory
    cd "$(dirname "$0")/novu"
    
    # Create namespace if it doesn't exist
    if ! kubectl get namespace novu >/dev/null 2>&1; then
        kubectl create namespace novu
        print_success "Created namespace 'novu'"
    fi
    
    # Install or upgrade Novu
    if helm list -n novu | grep -q novu; then
        print_info "Upgrading existing Novu installation..."
        helm upgrade novu . -n novu -f examples/minikube-values.yaml
    else
        print_info "Installing Novu..."
        helm install novu . -n novu -f examples/minikube-values.yaml
    fi
    
    print_success "Novu deployment initiated"
}

# Wait for deployment
wait_for_deployment() {
    print_info "Waiting for all pods to be ready (this may take several minutes)..."
    
    # Wait for all pods to be ready
    kubectl wait --for=condition=ready pod --all -n novu --timeout=600s
    
    print_success "All pods are ready!"
}

# Show access information
show_access_info() {
    print_info "Getting access information..."
    
    MINIKUBE_IP=$(minikube ip)
    
    echo ""
    print_success "Novu is now running on Minikube!"
    echo ""
    echo "Access URLs:"
    echo "  Dashboard: http://${MINIKUBE_IP}:30400"
    echo "  API:       http://${MINIKUBE_IP}:30300"
    echo "  WebSocket: http://${MINIKUBE_IP}:30302"
    echo ""
    echo "Alternative access using port-forwarding:"
    echo "  kubectl port-forward -n novu svc/novu-dashboard 4000:4000"
    echo "  kubectl port-forward -n novu svc/novu-api 3000:3000"
    echo "  kubectl port-forward -n novu svc/novu-ws 3002:3002"
    echo ""
    echo "Useful commands:"
    echo "  Check status: kubectl get pods -n novu"
    echo "  View logs:    kubectl logs -n novu deployment/novu-api -f"
    echo "  Uninstall:    helm uninstall novu -n novu"
    echo ""
}

# Show pod status
show_pod_status() {
    print_info "Current pod status:"
    kubectl get pods -n novu
    echo ""
}

# Main execution
main() {
    echo "🚀 Novu Minikube Deployment Script"
    echo "=================================="
    echo ""
    
    check_prerequisites
    start_minikube
    deploy_novu
    wait_for_deployment
    show_pod_status
    show_access_info
    
    print_success "Deployment completed successfully! 🎉"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Novu Minikube Deployment Script"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --status       Show current deployment status"
        echo "  --clean        Clean up the deployment"
        echo ""
        exit 0
        ;;
    --status)
        print_info "Checking Novu deployment status..."
        if kubectl get namespace novu >/dev/null 2>&1; then
            show_pod_status
            MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "N/A")
            echo "Access URLs:"
            echo "  Dashboard: http://${MINIKUBE_IP}:30400"
            echo "  API:       http://${MINIKUBE_IP}:30300"
            echo "  WebSocket: http://${MINIKUBE_IP}:30302"
        else
            print_warning "Novu is not deployed"
        fi
        exit 0
        ;;
    --clean)
        print_info "Cleaning up Novu deployment..."
        helm uninstall novu -n novu 2>/dev/null || true
        kubectl delete namespace novu 2>/dev/null || true
        print_success "Cleanup completed"
        exit 0
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        echo "Use --help for usage information"
        exit 1
        ;;
esac
