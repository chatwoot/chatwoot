# AlooChat Monitoring Stack

Comprehensive Prometheus and Grafana monitoring for AlooChat staging and production environments.

## 🚀 Quick Start

**For Staging:**
```bash
cd k8s/monitoring/staging
./deploy.sh
```

**For Production:**
```bash
cd k8s/monitoring/production
./deploy.sh
```

See [QUICKSTART.md](QUICKSTART.md) for detailed quick start guide.

## Overview

- **Prometheus**: Metrics collection and storage with configurable retention
- **Grafana**: Metrics visualization with pre-configured dashboards
- **Storage**: Persistent volumes (staging: 30Gi, production: 70Gi)
- **TLS**: Automatic certificate provisioning via cert-manager
- **Ingress**: HTTPS access via NGINX ingress controller

## Directory Structure

```
monitoring/
├── staging/                    # Staging environment (chatwoot-staging namespace)
│   ├── prometheus-config.yaml
│   ├── prometheus-deployment.yaml
│   ├── prometheus-ingress.yaml
│   ├── grafana-config.yaml
│   ├── grafana-deployment.yaml
│   ├── grafana-dashboard-aloochat.yaml
│   └── deploy.sh
├── production/                 # Production environment (default namespace)
│   ├── prometheus-config.yaml
│   ├── prometheus-deployment.yaml
│   ├── prometheus-ingress.yaml
│   ├── grafana-config.yaml
│   ├── grafana-deployment.yaml
│   ├── grafana-dashboard-aloochat.yaml
│   ├── deploy.sh
│   ├── README.md               # Production-specific guide
│   ├── DEPLOYMENT-PLAN.md      # Detailed deployment plan
│   └── DEPLOYMENT-SUMMARY.md   # Quick reference
├── PRODUCTION-VS-STAGING.md    # Environment comparison
├── QUICKSTART.md               # Quick start guide
└── README.md                   # This file
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

### Overview

Production monitoring is deployed to the `default` namespace with enhanced resources and 90-day data retention.

**Key Differences from Staging:**

| Feature | Staging | Production |
|---------|---------|------------|
| Namespace | `chatwoot-staging` | `default` |
| Ingress Class | `nginx-staging` | `nginx` |
| Ingress IP | `46.101.69.239` | `144.126.247.64` |
| Prometheus Storage | 20Gi | 50Gi |
| Grafana Storage | 10Gi | 20Gi |
| Data Retention | 30 days | 90 days |
| Prometheus CPU | 500m-2000m | 1000m-4000m |
| Prometheus Memory | 512Mi-2Gi | 1Gi-4Gi |
| Grafana CPU | 250m-1000m | 500m-2000m |
| Grafana Memory | 256Mi-1Gi | 512Mi-2Gi |

### Prerequisites

✅ **Before deploying to production:**

1. Staging monitoring validated for 24-48 hours
2. No issues in staging environment
3. Team trained on dashboards
4. Production credentials prepared
5. Deployment window scheduled
6. Rollback plan documented

### Quick Deployment

```bash
cd k8s/monitoring/production

# 1. Update Grafana password
nano grafana-deployment.yaml
# Change line ~22: admin-password: YOUR_STRONG_PASSWORD

# 2. Deploy using automated script
./deploy.sh

# 3. Configure DNS in Cloudflare
# Add A records for grafana.aloochat.ai and prometheus.aloochat.ai
# Point to: 144.126.247.64
# Proxy: DNS only (gray cloud)

# 4. Wait for TLS certificates (2-5 minutes)
kubectl get certificate -n default

# 5. Access your monitoring
# Grafana: https://grafana.aloochat.ai
# Prometheus: https://prometheus.aloochat.ai
```

### Detailed Documentation

For comprehensive production deployment instructions, see:

- **[production/README.md](production/README.md)** - Complete production guide with all commands
- **[production/DEPLOYMENT-PLAN.md](production/DEPLOYMENT-PLAN.md)** - Detailed step-by-step deployment plan
- **[production/DEPLOYMENT-SUMMARY.md](production/DEPLOYMENT-SUMMARY.md)** - Quick reference and troubleshooting
- **[PRODUCTION-VS-STAGING.md](PRODUCTION-VS-STAGING.md)** - Environment comparison and migration guide

### Production Access

**Grafana:**
- URL: https://grafana.aloochat.ai
- Username: `admin`
- Password: (stored in Kubernetes secret)

**Prometheus:**
- URL: https://prometheus.aloochat.ai
- No authentication (consider adding basic auth)

### Production Dashboards

1. **AlooChat Production - Kubernetes Cluster**
   - UID: `aloochat-production-k8s`
   - Real-time cluster metrics
   - Node and pod health
   - Resource usage

2. **AlooChat Production - Application Metrics**
   - UID: `aloochat-production-app`
   - HTTP request rates
   - Response times (p95, p99)
   - Error rates
   - Rails/Sidekiq status

### Production Monitoring

**What's Being Monitored:**

- ✅ Kubernetes API servers
- ✅ Kubernetes nodes (CPU, memory, disk)
- ✅ All pods in `default` namespace
- ✅ NGINX ingress controller
- ✅ AlooChat Rails application
- ✅ AlooChat Sidekiq workers
- ✅ Network traffic and errors

**Scrape Configuration:**

- Interval: 15 seconds
- Timeout: 10 seconds
- External labels: `cluster=aloochat-production`, `environment=production`

### Post-Deployment Validation

```bash
# Check pod health
kubectl get pods -n default -l app=prometheus
kubectl get pods -n default -l app=grafana

# Check resource usage
kubectl top pod -n default -l app=prometheus
kubectl top pod -n default -l app=grafana

# Check storage
kubectl get pvc -n default | grep -E "prometheus|grafana"

# Check certificates
kubectl get certificate -n default

# Check ingress
kubectl get ingress -n default | grep -E "prometheus|grafana"

# View logs
kubectl logs deployment/prometheus -n default --tail=50
kubectl logs deployment/grafana -n default --tail=50
```

### Production Maintenance

**Daily:**
- Monitor pod health
- Check for errors in logs
- Verify metrics collection

**Weekly:**
- Review storage usage
- Check certificate expiration
- Validate dashboard accuracy

**Monthly:**
- Review and optimize queries
- Update dashboards based on feedback
- Check for Prometheus/Grafana updates
- Backup Grafana configurations

### Backup Strategy

**Grafana Dashboards:**
```bash
# Export all dashboards
kubectl exec -n default deployment/grafana -- \
  curl -s http://localhost:3000/api/search | \
  jq -r '.[] | .uid' | \
  xargs -I {} kubectl exec -n default deployment/grafana -- \
  curl -s http://localhost:3000/api/dashboards/uid/{} > dashboard-{}.json
```

**Prometheus Data:**
- Stored in persistent volume (50Gi)
- Consider periodic snapshots of PVC
- 90-day retention configured

### Scaling Production

**When to Scale:**

- Prometheus storage > 70% full
- Query latency increasing
- CPU/Memory consistently at limits

**How to Scale:**

```bash
# Increase storage
kubectl edit pvc prometheus-storage -n default
# Update storage size, then restart pod

# Increase resources
kubectl edit deployment prometheus -n default
# Update CPU/Memory limits, changes apply automatically

# For high availability, consider:
# - Multiple Prometheus instances with Thanos
# - Prometheus federation
# - Remote write to long-term storage
```

## Security Considerations

1. **Change default passwords** immediately
2. **Enable authentication** on Prometheus if exposed externally
3. **Use TLS** for all external access
4. **Restrict RBAC** permissions to minimum required
5. **Regular backups** of Grafana dashboards and configuration

## Data Retention

### Staging
- **Prometheus**: 30 days (configurable via `--storage.tsdb.retention.time=30d`)
- **Grafana**: Permanent (stored in PVC)

### Production
- **Prometheus**: 90 days (configurable via `--storage.tsdb.retention.time=90d`)
- **Grafana**: Permanent (stored in PVC)

## Resource Requirements

### Staging

**Prometheus:**
- CPU: 500m request, 2000m limit
- Memory: 512Mi request, 2Gi limit
- Storage: 20Gi persistent volume

**Grafana:**
- CPU: 250m request, 1000m limit
- Memory: 256Mi request, 1Gi limit
- Storage: 10Gi persistent volume

**Total Storage:** ~30Gi (~$3/month on DigitalOcean)

### Production

**Prometheus:**
- CPU: 1000m (1 core) request, 4000m (4 cores) limit
- Memory: 1Gi request, 4Gi limit
- Storage: 50Gi persistent volume

**Grafana:**
- CPU: 500m request, 2000m (2 cores) limit
- Memory: 512Mi request, 2Gi limit
- Storage: 20Gi persistent volume

**Total Storage:** ~70Gi (~$7/month on DigitalOcean)

## Production Troubleshooting

### Common Production Issues

#### 1. Local DNS Cache Issues

**Symptom:** Browser can't find `grafana.aloochat.ai` even though DNS is configured.

**Solution:**
```bash
# Flush local DNS cache
sudo resolvectl flush-caches

# Or add to /etc/hosts temporarily
echo "144.126.247.64 grafana.aloochat.ai prometheus.aloochat.ai" | sudo tee -a /etc/hosts

# Verify DNS globally
dig @8.8.8.8 grafana.aloochat.ai +short
# Should return: 144.126.247.64
```

#### 2. Grafana Permission Errors

**Symptom:** Grafana crashing with "permission denied" on `/var/lib/grafana`.

**Solution:** Security context already configured in production deployment:
```yaml
securityContext:
  fsGroup: 472
  runAsUser: 472
  runAsNonRoot: true
```

If still having issues:
```bash
kubectl delete deployment grafana -n default
kubectl apply -f production/grafana-deployment.yaml
```

#### 3. Certificate Issues

**Symptom:** Certificates stuck in `READY = False`.

**Solution:**
```bash
# Verify DNS is not proxied (must be "DNS only" in Cloudflare)
nslookup grafana.aloochat.ai
# Should return: 144.126.247.64 (NOT Cloudflare IPs)

# Check certificate details
kubectl describe certificate grafana-production-tls -n default

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager --tail=50

# If needed, delete and recreate
kubectl delete certificate grafana-production-tls -n default
kubectl delete certificate prometheus-production-tls -n default
kubectl apply -f production/grafana-deployment.yaml
kubectl apply -f production/prometheus-ingress.yaml
```

#### 4. High Resource Usage

**Symptom:** Prometheus or Grafana using too much CPU/Memory.

**Solution:**
```bash
# Check current usage
kubectl top pod -n default -l app=prometheus
kubectl top pod -n default -l app=grafana

# Increase limits if needed
kubectl edit deployment prometheus -n default
kubectl edit deployment grafana -n default

# Or reduce scrape frequency in prometheus-config.yaml
# Change: scrape_interval: 15s
# To: scrape_interval: 30s
```

#### 5. Storage Full

**Symptom:** Prometheus storage reaching capacity.

**Solution:**
```bash
# Check storage usage
kubectl exec -n default deployment/prometheus -- df -h /prometheus

# Option 1: Reduce retention
kubectl edit deployment prometheus -n default
# Change: --storage.tsdb.retention.time=90d
# To: --storage.tsdb.retention.time=60d

# Option 2: Increase PVC size
kubectl edit pvc prometheus-storage -n default
# Update storage size, then restart pod
kubectl delete pod -n default -l app=prometheus
```

### Production Health Checks

**Daily Health Check Script:**
```bash
#!/bin/bash
echo "=== AlooChat Production Monitoring Health Check ==="
echo ""
echo "Pod Status:"
kubectl get pods -n default -l app=prometheus
kubectl get pods -n default -l app=grafana
echo ""
echo "Resource Usage:"
kubectl top pod -n default -l app=prometheus
kubectl top pod -n default -l app=grafana
echo ""
echo "Storage:"
kubectl get pvc -n default | grep -E "prometheus|grafana"
echo ""
echo "Certificates:"
kubectl get certificate -n default | grep -E "prometheus|grafana"
echo ""
echo "Recent Errors:"
kubectl logs deployment/prometheus -n default --tail=10 | grep -i error
kubectl logs deployment/grafana -n default --tail=10 | grep -i error
```

## Documentation Index

### Quick References
- **[QUICKSTART.md](QUICKSTART.md)** - Fast deployment guide for both environments
- **[PRODUCTION-VS-STAGING.md](PRODUCTION-VS-STAGING.md)** - Complete environment comparison

### Staging Documentation
- **[staging/deploy.sh](staging/deploy.sh)** - Automated staging deployment script
- Configurations in `staging/` directory

### Production Documentation
- **[production/README.md](production/README.md)** - Comprehensive production guide
- **[production/DEPLOYMENT-PLAN.md](production/DEPLOYMENT-PLAN.md)** - Detailed deployment plan with checklists
- **[production/DEPLOYMENT-SUMMARY.md](production/DEPLOYMENT-SUMMARY.md)** - Quick deployment summary
- **[production/deploy.sh](production/deploy.sh)** - Automated production deployment script
- Configurations in `production/` directory

## Support

### Getting Help

**For Staging Issues:**
```bash
# Check logs
kubectl logs -f deployment/prometheus -n chatwoot-staging
kubectl logs -f deployment/grafana -n chatwoot-staging

# Check Prometheus targets
kubectl port-forward svc/prometheus 9090:9090 -n chatwoot-staging
# Open: http://localhost:9090/targets
```

**For Production Issues:**
```bash
# Check logs
kubectl logs -f deployment/prometheus -n default
kubectl logs -f deployment/grafana -n default

# Check Prometheus targets
# Open: https://prometheus.aloochat.ai/targets

# Check Grafana datasources
# Open: https://grafana.aloochat.ai
# Go to: Configuration > Data Sources > Prometheus > Test
```

### Useful Commands Reference

```bash
# View all monitoring resources (staging)
kubectl get all -n chatwoot-staging -l app=prometheus
kubectl get all -n chatwoot-staging -l app=grafana

# View all monitoring resources (production)
kubectl get all -n default -l app=prometheus
kubectl get all -n default -l app=grafana

# Restart services
kubectl rollout restart deployment/prometheus -n <namespace>
kubectl rollout restart deployment/grafana -n <namespace>

# Get Grafana password
kubectl get secret grafana-credentials -n <namespace> -o jsonpath='{.data.admin-password}' | base64 -d

# Check certificate status
kubectl get certificate -n <namespace>

# View Prometheus config
kubectl get configmap prometheus-config -n <namespace> -o yaml
```

## Summary

This monitoring stack provides:

✅ **Complete observability** for AlooChat infrastructure and applications  
✅ **Separate environments** for staging validation and production monitoring  
✅ **Pre-configured dashboards** for immediate insights  
✅ **Automated deployment** with validation scripts  
✅ **Secure access** via HTTPS with automatic TLS certificates  
✅ **Persistent storage** with configurable retention periods  
✅ **Production-ready** with proper resource allocation and security  

**Current Status:**
- ✅ Staging: Deployed and validated
- ✅ Production: Deployed and operational
- ✅ DNS: Configured with TLS certificates
- ✅ Dashboards: Pre-configured and accessible
- ✅ Metrics: Collecting from all components

**Access URLs:**
- Staging Grafana: https://grafana-staging.aloochat.ai
- Staging Prometheus: https://prometheus-staging.aloochat.ai
- Production Grafana: https://grafana.aloochat.ai
- Production Prometheus: https://prometheus.aloochat.ai
