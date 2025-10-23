# AlooChat Monitoring Stack

This directory contains Prometheus and Grafana monitoring configurations for AlooChat deployments.

## Overview

- **Prometheus**: Metrics collection and storage
- **Grafana**: Metrics visualization and dashboards
- **Storage**: Persistent volumes for data retention (30 days for Prometheus, permanent for Grafana)

## Directory Structure

```
monitoring/
├── staging/           # Staging environment (chatwoot-staging namespace)
│   ├── prometheus-config.yaml
│   ├── prometheus-deployment.yaml
│   ├── grafana-config.yaml
│   ├── grafana-deployment.yaml
│   ├── grafana-dashboard-aloochat.yaml
│   └── deploy.sh
├── production/        # Production environment (default namespace)
│   └── (to be created after staging validation)
└── README.md
```

## Prerequisites

1. **Kubernetes cluster** with kubectl configured
2. **Storage class** available (uses `do-block-storage` by default)
3. **Ingress controller** (NGINX) already deployed
4. **cert-manager** for TLS certificates (optional but recommended)

## Staging Deployment

### Step 1: Verify Environment

**Check Ingress Class:**
```bash
kubectl get ingressclass
```

The configurations use `nginx-staging` for staging. If your ingress class has a different name, update:
- `staging/grafana-deployment.yaml` (search for `ingressClassName`)
- `staging/prometheus-ingress.yaml` (search for `ingressClassName`)

### Step 2: Review Configuration

Before deploying, customize these files:

1. **grafana-deployment.yaml**:
   - Change admin password in `grafana-credentials` secret (line ~22)
   - Verify ingress host: `grafana-staging.aloochat.ai`
   - Verify `ingressClassName: nginx-staging`

2. **prometheus-deployment.yaml**:
   - Storage size: 20Gi (adjust if needed)
   - Retention period: 30 days (adjust if needed)
   - Security context already configured for permissions

3. **prometheus-ingress.yaml**:
   - Verify ingress host: `prometheus-staging.aloochat.ai`
   - Verify `ingressClassName: nginx-staging`

### Step 3: Deploy Monitoring Stack

```bash
cd k8s/monitoring/staging

# Deploy Prometheus
kubectl apply -f prometheus-config.yaml
kubectl apply -f prometheus-deployment.yaml
kubectl apply -f prometheus-ingress.yaml

# Deploy Grafana
kubectl apply -f grafana-config.yaml
kubectl apply -f grafana-dashboard-aloochat.yaml
kubectl apply -f grafana-deployment.yaml

# Wait for pods to be ready
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n chatwoot-staging
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n chatwoot-staging
```

### Step 4: Configure DNS

**Get Ingress IP:**
```bash
kubectl get svc ingress-nginx-staging-controller -n chatwoot-staging -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

**Add DNS Records in Cloudflare:**

For both `grafana-staging` and `prometheus-staging`:
- Type: `A`
- Content: Your ingress IP (e.g., `46.101.69.239`)
- Proxy status: **DNS only** (gray cloud) ⚠️ Critical!
- TTL: Auto

**Why DNS only?** cert-manager needs direct access to verify domain ownership for Let's Encrypt certificates.

**Verify DNS:**
```bash
nslookup grafana-staging.aloochat.ai
nslookup prometheus-staging.aloochat.ai
# Should return your ingress IP, NOT Cloudflare IPs (104.x.x.x or 172.x.x.x)
```

### Step 5: Wait for TLS Certificates

```bash
# Check certificate status
kubectl get certificate -n chatwoot-staging

# Should show READY = True after 2-5 minutes
# NAME                     READY   SECRET                   AGE
# grafana-staging-tls      True    grafana-staging-tls      5m
# prometheus-staging-tls   True    prometheus-staging-tls   5m
```

If certificates are stuck in False state:
```bash
kubectl describe certificate grafana-staging-tls -n chatwoot-staging
kubectl describe certificate prometheus-staging-tls -n chatwoot-staging
```

### Step 6: Access Grafana & Prometheus

#### Option A: Port Forward (Immediate Access)

```bash
# Get admin password
kubectl get secret grafana-credentials -n chatwoot-staging -o jsonpath='{.data.admin-password}' | base64 -d
echo

# Port forward
kubectl port-forward svc/grafana 3000:3000 -n chatwoot-staging

# Open browser: http://localhost:3000
# Username: admin
# Password: (from command above)
```

#### Option B: Ingress (Production Access)

1. **Configure DNS**: Point `grafana-staging.aloochat.ai` to your ingress controller IP
2. **Wait for TLS**: cert-manager will automatically provision SSL certificate
3. **Access**: https://grafana-staging.aloochat.ai

### Step 4: Access Prometheus

```bash
# Port forward
kubectl port-forward svc/prometheus 9090:9090 -n chatwoot-staging

# Open browser: http://localhost:9090
```

## Available Dashboards

### 1. Kubernetes Cluster Dashboard
- **UID**: `chatwoot-staging-k8s`
- **Metrics**:
  - CPU usage per node
  - Memory usage per pod
  - Running pods count
  - Request rate

### 2. AlooChat Application Dashboard
- **UID**: `aloochat-staging-app`
- **Metrics**:
  - HTTP request rate
  - Response time (p95, p99)
  - Rails/Sidekiq pod status
  - 5xx error rate
  - Memory usage per component
  - CPU usage per component

## Monitored Components

- **Rails Application** (`chatwoot-rails-staging`)
- **Sidekiq Workers** (`chatwoot-sidekiq-staging`)
- **NGINX Ingress Controller**
- **Redis** (if metrics exposed)
- **Kubernetes Nodes and Pods**

## Metrics Endpoints

The monitoring stack scrapes metrics from:

1. **Kubernetes API**: Node and pod metrics
2. **NGINX Ingress**: Request metrics on port 10254
3. **Application Pods**: Via annotations (if configured)

## Adding Metrics to AlooChat

To expose metrics from Rails application, add to your Gemfile:

```ruby
gem 'prometheus-client'
gem 'prometheus_exporter'
```

Then add to `config/initializers/prometheus.rb`:

```ruby
require 'prometheus_exporter/middleware'

# This reports stats per request like HTTP status and timings
Rails.application.middleware.unshift PrometheusExporter::Middleware
```

And add annotations to pod spec:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "9394"
    prometheus.io/path: "/metrics"
```

## Troubleshooting

### Common Issues and Solutions

#### 1. 404 Not Found or NGINX Error

**Symptom:** Getting 404 or NGINX error when accessing `grafana-staging.aloochat.ai` or `prometheus-staging.aloochat.ai`.

**Cause:** Ingress class name mismatch.

**Solution:**
```bash
# Check your ingress class
kubectl get ingressclass

# Update ingress configurations to match
# Edit staging/grafana-deployment.yaml and staging/prometheus-ingress.yaml
# Change: ingressClassName: nginx
# To: ingressClassName: nginx-staging (or your actual ingress class name)

# Reapply
kubectl apply -f staging/grafana-deployment.yaml
kubectl apply -f staging/prometheus-ingress.yaml
```

#### 2. DNS Pointing to Cloudflare IPs

**Symptom:** `nslookup` shows Cloudflare IPs (104.x.x.x or 172.x.x.x) instead of server IP.

**Cause:** Cloudflare proxy is enabled (orange cloud).

**Solution:**
1. Go to Cloudflare DNS settings
2. Find `grafana-staging` and `prometheus-staging` A records
3. Click the orange cloud to change to gray cloud (DNS only)
4. Verify:
   ```bash
   nslookup grafana-staging.aloochat.ai
   # Should return your ingress IP (e.g., 46.101.69.239)
   ```

#### 3. TLS Certificates Not Ready

**Symptom:** Certificates stuck in `READY = False` state.

**Common causes:**
- DNS pointing to Cloudflare proxy (must be DNS only)
- Wrong ingress class name
- cert-manager not running properly

**Solution:**
```bash
# Check certificate details
kubectl describe certificate grafana-staging-tls -n chatwoot-staging

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Verify DNS is correct (not proxied)
nslookup grafana-staging.aloochat.ai

# If needed, delete and recreate certificates
kubectl delete certificate grafana-staging-tls -n chatwoot-staging
kubectl delete certificate prometheus-staging-tls -n chatwoot-staging
kubectl apply -f staging/grafana-deployment.yaml
kubectl apply -f staging/prometheus-ingress.yaml
```

#### 4. Prometheus Permission Errors

**Symptom:** Prometheus crashing with "permission denied" on `/prometheus/queries.active`.

**Cause:** Missing security context for volume permissions.

**Solution:** Already fixed in current deployment with:
```yaml
securityContext:
  fsGroup: 65534
  runAsUser: 65534
  runAsNonRoot: true
```

If still having issues:
```bash
# Delete and recreate deployment
kubectl delete deployment prometheus -n chatwoot-staging
kubectl apply -f staging/prometheus-deployment.yaml
```

#### 5. Prometheus not scraping targets

```bash
# Check Prometheus logs
kubectl logs -f deployment/prometheus -n chatwoot-staging

# Check targets in Prometheus UI
# Navigate to: http://localhost:9090/targets
```

#### 6. Grafana not showing data

```bash
# Check Grafana logs
kubectl logs -f deployment/grafana -n chatwoot-staging

# Verify Prometheus datasource
# In Grafana: Configuration > Data Sources > Prometheus > Test

# Check Prometheus is running
kubectl get pods -n chatwoot-staging -l app=prometheus
```

#### 7. Storage issues

```bash
# Check PVC status
kubectl get pvc -n chatwoot-staging

# Check PV status
kubectl get pv | grep chatwoot-staging

# Describe PVC for details
kubectl describe pvc prometheus-storage -n chatwoot-staging
kubectl describe pvc grafana-storage -n chatwoot-staging
```

## Useful Commands

```bash
# View all monitoring resources
kubectl get all -n chatwoot-staging -l app=prometheus
kubectl get all -n chatwoot-staging -l app=grafana

# Check resource usage
kubectl top pods -n chatwoot-staging

# View Prometheus config
kubectl get configmap prometheus-config -n chatwoot-staging -o yaml

# Restart Prometheus
kubectl rollout restart deployment/prometheus -n chatwoot-staging

# Restart Grafana
kubectl rollout restart deployment/grafana -n chatwoot-staging

# Delete monitoring stack
kubectl delete -f staging/
```

## Alerts Configuration

To add alerting, create `prometheus-rules.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-rules
  namespace: chatwoot-staging
data:
  alerts.yml: |
    groups:
      - name: aloochat
        interval: 30s
        rules:
          - alert: HighErrorRate
            expr: sum(rate(nginx_ingress_controller_requests{status=~"5.."}[5m])) > 10
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "High 5xx error rate detected"
          
          - alert: PodDown
            expr: kube_pod_status_phase{namespace="chatwoot-staging", phase!="Running"} > 0
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "Pod {{ $labels.pod }} is not running"
```

## Production Deployment

After validating staging:

1. Copy staging configuration to production directory
2. Update namespace to `default`
3. Update ingress host to `grafana.aloochat.ai`
4. Update admin password
5. Deploy using similar process

## Security Considerations

1. **Change default passwords** immediately
2. **Enable authentication** on Prometheus if exposed externally
3. **Use TLS** for all external access
4. **Restrict RBAC** permissions to minimum required
5. **Regular backups** of Grafana dashboards and configuration

## Data Retention

- **Prometheus**: 30 days (configurable via `--storage.tsdb.retention.time`)
- **Grafana**: Permanent (stored in PVC)

## Resource Requirements

### Prometheus
- **CPU**: 500m request, 2000m limit
- **Memory**: 512Mi request, 2Gi limit
- **Storage**: 20Gi

### Grafana
- **CPU**: 250m request, 1000m limit
- **Memory**: 256Mi request, 1Gi limit
- **Storage**: 10Gi

## Support

For issues or questions:
- Check logs: `kubectl logs -f <pod-name> -n chatwoot-staging`
- Review Prometheus targets: http://localhost:9090/targets
- Review Grafana datasources: Configuration > Data Sources
