#!/bin/bash
# setup.sh - Full setup for the voting app challenge

set -e

log() {
    echo "[INFO] $1"
}

error() {
    echo "[ERROR] $1"
    exit 1
}

# Check if we're in the right directory
if [ ! -f "values.yaml" ] || [ ! -d "templates" ]; then
    error "Please run this from the helm-chart/ directory"
fi

log "Starting complete setup for the voting app challenge..."

# 1. Check prerequisites
log "Checking prerequisites..."
command -v docker >/dev/null || error "Docker is required"
command -v kubectl >/dev/null || error "kubectl is required"
command -v helm >/dev/null || error "helm is required"
command -v minikube >/dev/null || error "minikube is required"

# 2. Start minikube
log "Setting up Kubernetes cluster..."
if ! minikube status >/dev/null 2>&1; then
    minikube start --cpus=4 --memory=3900 --disk-size=20gb
fi

# 3. Enable required addons
log "Enabling addons..."
minikube addons enable ingress
minikube addons enable metrics-server

# 4. Wait for ingress to be ready
log "Waiting for Ingress Controller..."
kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=300s

# 5. Load local images into minikube
log "Loading local images..."
minikube image load votes-api:v1-fixed
minikube image load votes-ui:v1-fixed

# Verify images were loaded
log "Verifying images..."
minikube image ls | grep votes || error "Images weren't loaded correctly"

# 6. Deploy the application
log "Deploying application..."
helm install voting-app . --wait --timeout=600s

# 7. Set up local DNS
log "Configuring local DNS..."
MINIKUBE_IP=$(minikube ip)
sudo sed -i.bak '/voting-app.local/d' /etc/hosts 2>/dev/null || true
echo "$MINIKUBE_IP voting-app.local" | sudo tee -a /etc/hosts

# 8. Start tunnel
log "Starting tunnel..."
pkill -f "minikube tunnel" 2>/dev/null || true
sudo minikube tunnel >/dev/null 2>&1 &
TUNNEL_PID=$!
echo $TUNNEL_PID > /tmp/minikube-tunnel.pid

# 9. Wait for all pods to be ready
log "Waiting for application to become ready..."
kubectl wait --for=condition=ready pod --all --timeout=600s

# 10. Show status
log "Deployment status:"
kubectl get pods -o wide
kubectl get svc
kubectl get ingress

# 11. Test connectivity
log "Setting up access..."

# Wait for ingress configuration
sleep 30

# Test via ingress
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://voting-app.local 2>/dev/null || echo "000")

if [ "$RESPONSE" = "200" ]; then
    log "Application accessible at http://voting-app.local"
    ACCESS_URL="http://voting-app.local"
    
    # Test voting functionality
    log "Testing voting functionality..."
    VOTE_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
         -d '{"vote":"a","voter_id":"test123"}' \
         http://voting-app.local/vote 2>/dev/null | grep -o "success" || echo "fail")
    
    if [ "$VOTE_RESPONSE" = "success" ]; then
        log "Voting API is working correctly"
    else
        error "Voting API isn't responding properly"
    fi
else
    log "Setting up port-forward fallback..."
    pkill -f "kubectl port-forward" 2>/dev/null || true
    kubectl port-forward svc/votes-ui-service 8080:4000 >/dev/null 2>&1 &
    echo $! > /tmp/port-forward-ui.pid
    kubectl port-forward svc/votes-api-service 8085:80 >/dev/null 2>&1 &
    echo $! > /tmp/port-forward-api.pid
    sleep 5
    ACCESS_URL="http://localhost:8080"
    
    # Final test
    FINAL_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $ACCESS_URL 2>/dev/null || echo "000")
    if [ "$FINAL_RESPONSE" != "200" ]; then
        error "Application isn't responding correctly"
    fi
fi

# 12. Show final summary
echo ""
echo "=================================="
echo "  VOTING APP CHALLENGE COMPLETE"
echo "=================================="
echo ""
echo "Access your application at:"
echo "  $ACCESS_URL"
echo ""
echo "Features:"
echo "  • Voting interface (Cats vs Dogs)"
echo "  • Real-time results"
echo "  • Working backend API"
echo "  • PostgreSQL database"
echo ""
echo "To verify:"
echo "1. Open: $ACCESS_URL"
echo "2. Vote for Cats or Dogs"
echo "3. Watch results update in real-time"
echo ""

if [[ "$ACCESS_URL" == *"localhost"* ]]; then
    echo "NOTE: Keep this terminal open"
    echo "(port-forwards are active for access)"
fi

echo ""
echo "Setup completed successfully!"
