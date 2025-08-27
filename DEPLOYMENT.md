# DevOps Challenge by OMAR MARTINEZ CloudKing B) 

A production-ready containerized voting application built with Kubernetes, Helm, and microservices architecture.

## Quick Start

This application demonstrates a complete microservices deployment using Kubernetes orchestration. The setup is fully automated and requires only 4 commands to deploy.

### Prerequisites

Ensure you have the following tools installed and running:

- **Docker Desktop** (v4.0+)
- **kubectl** (v1.25+)
- **Helm** (v3.8+)
- **minikube** (v1.25+)
- **macOS/Linux** with sudo access

### Installation & Deployment

```bash
# 1. Clone the repository
git clone https://github.com/omarmart7/devops-challenge
cd devops-challenge

# 2. Build application images
docker build -t votes-api:v1-fixed votes-api/
docker build -t votes-ui:v1-fixed votes-ui/

# 3. Navigate to helm chart directory
cd helm-chart

# 4. Deploy the entire stack 
chmod +x setup.sh 
./setup.sh

# 5. WHEN YOU FINISH AND WANT TO DELETE EVERYTHING NOT BEFORE TESTING THE APP 
#### THIS WILL DELETE ALL THE RESOURCES CREATED BY THIS DEPLOYMENT, IMAGES, FILES, REPO, MINIKUBE etc DONT WORRY I WONT HACK YOU 
chmod +x nuclear-bomb.sh
./nuclear-bomb.sh 

The setup script will:
- Initialize minikube cluster
- Enable ingress and metrics-server addons
- Load Docker images into minikube
- Deploy PostgreSQL, Backend API, and Frontend
- Configure networking and DNS
- Provide access URL (typically `http://localhost:8080`)

### Accessing the Application

After deployment completes, the application will be available at the URL displayed in the terminal output. Open your browser to:

- Vote between Cats vs Dogs
- View real-time results
- See live vote counts and percentages

## Architecture Overview

### Components

**Frontend (votes-ui)**
- Node.js + Express server
- AngularJS single-page application
- Socket.IO for real-time updates
- Port: 4000

**Backend (votes-api)**
- Python Flask REST API
- PostgreSQL database integration
- JSON API endpoints for voting and results
- Port: 80

**Database (postgres)**
- PostgreSQL 13
- Persistent volume storage
- Automatic schema creation
- Port: 5432

### Kubernetes Resources

The application deploys the following Kubernetes resources:

- **Deployments**: Application pod management with 2 replicas each
- **Services**: Internal load balancing and service discovery
- **Ingress**: External HTTP routing and SSL termination
- **PersistentVolumeClaim**: Database storage persistence
- **Secrets**: Database credentials management
- **HorizontalPodAutoscaler**: CPU-based automatic scaling
- **NetworkPolicies**: Pod-to-pod communication security

### High Availability Features

- **Multi-replica deployments** for fault tolerance
- **Rolling updates** for zero-downtime deployments
- **Health checks** with automatic pod restart
- **Horizontal auto-scaling** based on CPU utilization
- **Persistent storage** for data durability
- **Load balancing** across multiple pod instances

## API Endpoints

The backend exposes the following REST endpoints:

- `GET /` - API information and voting options
- `GET /healthz` - Health check endpoint
- `POST /vote` - Submit a vote (JSON: `{"vote": "a", "voter_id": "uuid"}`)
- `GET /results` - Current voting results

## Configuration

### Environment Variables

**Backend (votes-api)**
- `POSTGRES_HOST`: Database hostname
- `POSTGRES_USER`: Database username  
- `POSTGRES_PASSWORD`: Database password
- `POSTGRES_DB`: Database name
- `OPTION_A`: First voting option (default: "Cats")
- `OPTION_B`: Second voting option (default: "Dogs")
- `PORT`: Application port (default: "80")

**Frontend (votes-ui)**
- `VOTES_API_HOST`: Backend service hostname
- `VOTES_API_PORT`: Backend service port
- `PORT`: Application port (default: "4000")

### Customization

Modify `helm-chart/values.yaml` to customize:
- Replica counts
- Resource limits and requests
- Environment variables
- Auto-scaling parameters
- Storage requirements

## Development & Testing

### Local Development

For local development without Kubernetes:

```bash
# Start PostgreSQL
docker run -d --name postgres -e POSTGRES_PASSWORD=postgres postgres:13

# Start backend
cd votes-api
pip install -r requirements.txt
export POSTGRES_HOST=localhost
python app.py

# Start frontend  
cd votes-ui
npm install
export VOTES_API_HOST=localhost
export VOTES_API_PORT=5000
node server.js
```

### Debugging

View application logs:
```bash
kubectl logs -f deployment/votes-api-deployment
kubectl logs -f deployment/votes-ui-deployment
kubectl logs -f deployment/postgres-deployment
```

Check pod status:
```bash
kubectl get pods -o wide
kubectl describe pod <pod-name>
```

Port-forward for direct access:
```bash
kubectl port-forward svc/votes-ui-service 8080:4000
kubectl port-forward svc/votes-api-service 8081:80
```

## Troubleshooting

### Common Issues

**Setup script fails with "images not found"**
- Ensure Docker images were built successfully
- Verify minikube is running: `minikube status`

**Application returns 404 errors**
- Check if both port-forwards are active in fallback mode
- Verify ingress controller is running: `kubectl get pods -n ingress-nginx`

**Database connection errors**
- Check PostgreSQL pod status: `kubectl get pods`
- Verify secrets are properly mounted: `kubectl describe secret postgres-secret`

**Performance issues**
- Monitor resource usage: `kubectl top pods`
- Check HPA status: `kubectl get hpa`

### Manual Recovery

If automatic deployment fails, use these commands:

```bash
# Restart failed pods
kubectl delete pods -l app=votes-api
kubectl delete pods -l app=votes-ui

# Recreate persistent volume
kubectl delete pvc postgres-pvc
helm upgrade voting-app . --wait

# Reset networking
sudo pkill -f "minikube tunnel"
sudo minikube tunnel &
```

## Security Features

- **Network segmentation** with NetworkPolicies
- **Encrypted secrets** for database credentials  
- **Non-root containers** for reduced attack surface
- **Resource limits** to prevent resource exhaustion
- **Health checks** for automatic failure detection

## Monitoring & Observability

The application includes:
- Health check endpoints for liveness/readiness probes
- Structured logging with request/response tracking
- CPU and memory metrics collection
- Auto-scaling based on resource utilization

## Performance Characteristics

**Scalability**
- Horizontal scaling: 2-8 replicas based on CPU load
- Database connection pooling
- Stateless application design

**Resource Requirements**
- Minimum: 2 CPU cores, 4GB RAM
- Recommended: 4 CPU cores, 8GB RAM
- Storage: 10GB persistent volume for database

## Production Readiness

This deployment includes production-grade features:

- **High availability** with multiple replicas
- **Automatic scaling** based on demand
- **Rolling deployments** for zero downtime
- **Persistent data storage** for vote retention
- **Security policies** for network isolation
- **Health monitoring** for service reliability
- **Resource management** for optimal performance

The application is designed to handle production workloads with proper monitoring, security, and scalability patterns.
