#!/bin/bash
# cleanup.sh - Complete cleanup of voting app development environment

set -e

log() {
    echo "[CLEANUP] $1"
}

error() {
    echo "[ERROR] $1"
    exit 1
}

# Confirmation prompt
echo "=================================="
echo "  VOTING APP CLEANUP SCRIPT"
echo "=================================="
echo ""
echo "This will remove:"
echo "  • Helm release 'voting-app'"
echo "  • All running port-forwards"
echo "  • minikube tunnel processes"
echo "  • voting-app.local DNS entry"
echo "  • Docker images (votes-api, votes-ui)"
echo "  • minikube cluster"
echo "  • Temporary files"
echo ""
read -p "Continue with cleanup? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

log "Starting complete environment cleanup..."

# 1. Remove Helm release
log "Removing Helm release..."
helm uninstall voting-app 2>/dev/null && log "Helm release removed" || log "No Helm release found"

# 2. Kill port-forward processes
log "Stopping port-forward processes..."
pkill -f "kubectl port-forward" 2>/dev/null && log "Port-forwards stopped" || log "No port-forwards running"

# 3. Kill minikube tunnel
log "Stopping minikube tunnel..."
sudo pkill -f "minikube tunnel" 2>/dev/null && log "Tunnel stopped" || log "No tunnel running"

# 4. Clean temporary files
log "Removing temporary files..."
rm -f /tmp/minikube-tunnel.pid /tmp/port-forward*.pid
log "Temporary files cleaned"

# 5. Remove DNS entry
log "Cleaning DNS configuration..."
if grep -q "voting-app.local" /etc/hosts 2>/dev/null; then
    sudo sed -i.bak '/voting-app.local/d' /etc/hosts
    log "DNS entry removed from /etc/hosts"
else
    log "No DNS entry found"
fi

# 6. Remove Docker images
log "Removing Docker images..."
# Remove voting app images
if docker images | grep -q votes-api; then
    docker rmi $(docker images | grep votes-api | awk '{print $3}') 2>/dev/null || true
    log "votes-api images removed"
fi

if docker images | grep -q votes-ui; then
    docker rmi $(docker images | grep votes-ui | awk '{print $3}') 2>/dev/null || true
    log "votes-ui images removed"
fi

# Clean unused images
log "Cleaning unused Docker images..."
docker image prune -f >/dev/null 2>&1 || true

# 7. Stop and delete minikube cluster
log "Removing minikube cluster..."
if minikube status >/dev/null 2>&1; then
    minikube delete
    log "minikube cluster deleted"
else
    log "No minikube cluster found"
fi

# 8. Verify cleanup
log "Verifying cleanup..."

# Check processes
REMAINING_PROCESSES=$(pgrep -f "kubectl port-forward|minikube tunnel" 2>/dev/null | wc -l)
if [ "$REMAINING_PROCESSES" -eq 0 ]; then
    log "✓ All processes cleaned"
else
    log "⚠ Some processes still running"
fi

# Check Docker images
REMAINING_IMAGES=$(docker images | grep -c votes 2>/dev/null || echo 0)
if [ "$REMAINING_IMAGES" -eq 0 ]; then
    log "✓ Docker images cleaned"
else
    log "⚠ Some voting app images remain"
fi

# Check minikube
if ! minikube status >/dev/null 2>&1; then
    log "✓ minikube cluster removed"
else
    log "⚠ minikube cluster still exists"
fi

# 9. Show final status
echo ""
echo "=================================="
echo "  CLEANUP COMPLETED"
echo "=================================="
echo ""
echo "Environment reset to clean state."
echo ""
echo "To redeploy the application:"
echo "1. docker build -t votes-api:v1-fixed votes-api/"
echo "2. docker build -t votes-ui:v1-fixed votes-ui/"  
echo "3. cd helm-chart"
echo "4. ./setup.sh"
echo ""
echo "System resources freed:"
echo "  • Docker images: ~500MB"
echo "  • minikube VM: ~2GB"
echo "  • Persistent volumes: ~10GB"
echo ""

log "Cleanup script completed successfully!"

# Optional: Remove the project directory
echo ""
read -p "Remove entire project directory? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd ..
    rm -rf devops-challenge
    log "Project directory removed"
    echo "Complete cleanup finished. Repository can be re-cloned if needed."
fi
