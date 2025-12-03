#!/bin/bash

# AlooChat Production Monitoring Stack Deployment Script
# This script deploys Prometheus and Grafana to the production (default) namespace

set -e

echo "=========================================="
echo "AlooChat Production Monitoring Deployment"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed or not in PATH${NC}"
    exit 1
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Connected to Kubernetes cluster${NC}"
echo ""

# Confirm production deployment
echo -e "${YELLOW}WARNING: You are about to deploy to PRODUCTION (default namespace)${NC}"
echo -e "${YELLOW}This will create monitoring resources in your production environment.${NC}"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
echo ""
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Check if Grafana password has been changed
if grep -q "AlooChat2025!Production#Secure" grafana-deployment.yaml; then
    echo -e "${YELLOW}WARNING: Default Grafana password detected!${NC}"
    echo -e "${YELLOW}Please change the password in grafana-deployment.yaml before deploying to production.${NC}"
    echo ""
    read -p "Continue anyway? (yes/no): " -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Deployment cancelled. Please update the password and try again."
        exit 0
    fi
fi

echo "Step 1/9: Deploying Prometheus configuration..."
kubectl apply -f prometheus-config.yaml
echo -e "${GREEN}✓ Prometheus configuration deployed${NC}"
echo ""

echo "Step 2/9: Deploying Prometheus..."
kubectl apply -f prometheus-deployment.yaml
echo -e "${GREEN}✓ Prometheus deployed${NC}"
echo ""

echo "Step 3/9: Deploying Prometheus ingress..."
kubectl apply -f prometheus-ingress.yaml
echo -e "${GREEN}✓ Prometheus ingress deployed${NC}"
echo ""

echo "Step 4/9: Deploying Loki configuration..."
kubectl apply -f loki-config.yaml
echo -e "${GREEN}✓ Loki configuration deployed${NC}"
echo ""

echo "Step 5/9: Deploying Loki..."
kubectl apply -f loki-deployment.yaml
echo -e "${GREEN}✓ Loki deployed${NC}"
echo ""

echo "Step 6/9: Deploying Promtail (log collector)..."
kubectl apply -f promtail-config.yaml
kubectl apply -f promtail-daemonset.yaml
echo -e "${GREEN}✓ Promtail deployed${NC}"
echo ""

echo "Step 7/9: Deploying Grafana configuration..."
kubectl apply -f grafana-config.yaml
echo -e "${GREEN}✓ Grafana configuration deployed${NC}"
echo ""

echo "Step 8/9: Deploying Grafana dashboards..."
kubectl apply -f grafana-dashboard-aloochat.yaml
kubectl apply -f grafana-dashboard-logs.yaml
echo -e "${GREEN}✓ Grafana dashboards deployed${NC}"
echo ""

echo "Step 9/9: Deploying Grafana..."
kubectl apply -f grafana-deployment.yaml
echo -e "${GREEN}✓ Grafana deployed${NC}"
echo ""

echo "=========================================="
echo "Waiting for pods to be ready..."
echo "=========================================="
echo ""

# Wait for Prometheus
echo "Waiting for Prometheus..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n default || {
    echo -e "${RED}Error: Prometheus deployment failed${NC}"
    echo "Check logs with: kubectl logs -f deployment/prometheus -n default"
    exit 1
}
echo -e "${GREEN}✓ Prometheus is ready${NC}"
echo ""

# Wait for Loki
echo "Waiting for Loki..."
kubectl wait --for=condition=available --timeout=300s deployment/loki -n default || {
    echo -e "${RED}Error: Loki deployment failed${NC}"
    echo "Check logs with: kubectl logs -f deployment/loki -n default"
    exit 1
}
echo -e "${GREEN}✓ Loki is ready${NC}"
echo ""

# Wait for Grafana
echo "Waiting for Grafana..."
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n default || {
    echo -e "${RED}Error: Grafana deployment failed${NC}"
    echo "Check logs with: kubectl logs -f deployment/grafana -n default"
    exit 1
}
echo -e "${GREEN}✓ Grafana is ready${NC}"
echo ""

echo "=========================================="
echo "Deployment Summary"
echo "=========================================="
echo ""

# Get pod status
echo "Pod Status:"
kubectl get pods -n default -l app=prometheus
kubectl get pods -n default -l app=loki
kubectl get pods -n default -l app=promtail
kubectl get pods -n default -l app=grafana
echo ""

# Get service status
echo "Service Status:"
kubectl get svc -n default -l app=prometheus
kubectl get svc -n default -l app=loki
kubectl get svc -n default -l app=grafana
echo ""

# Get ingress status
echo "Ingress Status:"
kubectl get ingress -n default prometheus
kubectl get ingress -n default grafana
echo ""

# Get admin password
echo "=========================================="
echo "Access Information"
echo "=========================================="
echo ""
echo "Grafana Admin Credentials:"
echo "  Username: admin"
echo -n "  Password: "
kubectl get secret grafana-credentials -n default -o jsonpath='{.data.admin-password}' | base64 -d
echo ""
echo ""

echo "Access URLs (after DNS configuration):"
echo "  Grafana: https://grafana.aloochat.ai"
echo "  Prometheus: https://prometheus.aloochat.ai"
echo ""

echo "Port Forward Access (immediate):"
echo "  Grafana: kubectl port-forward svc/grafana 3000:3000 -n default"
echo "  Prometheus: kubectl port-forward svc/prometheus 9090:9090 -n default"
echo ""

echo "=========================================="
echo "Next Steps"
echo "=========================================="
echo ""
echo "1. Configure DNS in Cloudflare:"
echo "   - grafana.aloochat.ai → Your ingress IP"
echo "   - prometheus.aloochat.ai → Your ingress IP"
echo "   - Set proxy to 'DNS only' (gray cloud)"
echo ""
echo "2. Get ingress IP:"
echo "   kubectl get svc ingress-nginx-controller -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}'"
echo ""
echo "3. Wait for TLS certificates (2-5 minutes):"
echo "   kubectl get certificate -n default"
echo ""
echo "4. Access Grafana and verify dashboards"
echo ""

echo -e "${GREEN}✓ Production monitoring stack deployed successfully!${NC}"
