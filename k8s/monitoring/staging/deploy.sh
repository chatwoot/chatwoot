#!/bin/bash

set -e

echo "🚀 Deploying Monitoring Stack to chatwoot-staging namespace..."
echo ""

# Check if namespace exists
if ! kubectl get namespace chatwoot-staging &> /dev/null; then
    echo "Error: chatwoot-staging namespace does not exist"
    exit 1
fi

echo "📊 Step 1: Deploying Prometheus..."
kubectl apply -f prometheus-config.yaml
kubectl apply -f prometheus-deployment.yaml
echo "✅ Prometheus configuration applied"
echo ""

echo "📈 Step 2: Deploying Grafana..."
kubectl apply -f grafana-config.yaml
kubectl apply -f grafana-dashboard-aloochat.yaml
kubectl apply -f grafana-deployment.yaml
echo "✅ Grafana configuration applied"
echo ""

echo "⏳ Step 3: Waiting for Prometheus to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n chatwoot-staging
echo "✅ Prometheus is ready"
echo ""

echo "⏳ Step 4: Waiting for Grafana to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n chatwoot-staging
echo "✅ Grafana is ready"
echo ""

echo "📋 Getting service information..."
echo ""
echo "Prometheus Service:"
kubectl get svc prometheus -n chatwoot-staging
echo ""
echo "Grafana Service:"
kubectl get svc grafana -n chatwoot-staging
echo ""

echo "🎉 Monitoring stack deployed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Get Grafana admin password:"
echo "   kubectl get secret grafana-credentials -n chatwoot-staging -o jsonpath='{.data.admin-password}' | base64 -d"
echo ""
echo "2. Port-forward to access Grafana locally:"
echo "   kubectl port-forward svc/grafana 3000:3000 -n chatwoot-staging"
echo "   Then open: http://localhost:3000"
echo ""
echo "3. Or access via ingress (after DNS is configured):"
echo "   https://grafana-staging.aloochat.ai"
echo ""
echo "4. Port-forward to access Prometheus locally:"
echo "   kubectl port-forward svc/prometheus 9090:9090 -n chatwoot-staging"
echo "   Then open: http://localhost:9090"
echo ""
