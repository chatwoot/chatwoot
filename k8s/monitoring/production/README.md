# AlooChat Production Monitoring Stack

Complete Prometheus and Grafana monitoring setup for AlooChat production environment.

---

## 📋 Overview

This directory contains production-ready monitoring configurations for:
- **Prometheus**: Metrics collection and storage (90-day retention)
- **Grafana**: Metrics visualization with pre-configured dashboards
- **Namespace**: `default` (production)
- **Domains**: `grafana.aloochat.ai` and `prometheus.aloochat.ai`

---

## 🔧 Production Specifications

### Prometheus
- **Storage**: 50Gi persistent volume
- **Retention**: 90 days
- **Resources**: 1-4 CPU cores, 1-4Gi memory
- **Security**: RBAC enabled, security context configured

### Grafana
- **Storage**: 20Gi persistent volume
- **Resources**: 500m-2 CPU cores, 512Mi-2Gi memory
- **Features**: Pre-configured dashboards, Prometheus datasource

### Differences from Staging
| Feature | Staging | Production |
|---------|---------|------------|
| Namespace | `chatwoot-staging` | `default` |
| Ingress Class | `nginx-staging` | `nginx` |
| Prometheus Storage | 20Gi | 50Gi |
| Retention Period | 30 days | 90 days |
| Prometheus Resources | 512Mi-2Gi | 1Gi-4Gi |
| Grafana Storage | 10Gi | 20Gi |
| Domains | `*-staging.aloochat.ai` | `*.aloochat.ai` |

---

## 📦 Files Included

```
production/
├── prometheus-config.yaml          # Prometheus scrape configuration
├── prometheus-deployment.yaml      # Prometheus deployment + RBAC + storage
├── prometheus-ingress.yaml         # Prometheus ingress with TLS
├── grafana-config.yaml            # Grafana datasources + dashboard config
├── grafana-dashboard-aloochat.yaml # AlooChat application dashboard
├── grafana-deployment.yaml        # Grafana deployment + ingress + storage
├── deploy.sh                      # Automated deployment script
└── README.md                      # This file
```

---

## 🚀 Deployment Guide

### Prerequisites

1. ✅ **Kubernetes cluster** with kubectl configured for production
2. ✅ **Storage class** `do-block-storage` available
3. ✅ **Ingress controller** (nginx) deployed in default namespace
4. ✅ **cert-manager** installed for TLS certificates
5. ✅ **Staging validated** - Ensure staging monitoring works correctly

### Step 1: Review and Update Configuration

**CRITICAL: Update Grafana Password**

Edit `grafana-deployment.yaml` and change the admin password:

```yaml
stringData:
  admin-user: admin
  admin-password: YOUR_STRONG_PASSWORD_HERE  # CHANGE THIS!
```

**Verify Ingress Class**

Check your production ingress class:

```bash
kubectl get ingressclass
# Should show: nginx (for production)
```

If different, update:
- `grafana-deployment.yaml` (line with `ingressClassName`)
- `prometheus-ingress.yaml` (line with `ingressClassName`)

### Step 2: Deploy Using Script (Recommended)

```bash
cd k8s/monitoring/production
./deploy.sh
```

The script will:
- ✅ Verify cluster connectivity
- ✅ Confirm production deployment
- ✅ Warn if default password is used
- ✅ Deploy all components in order
- ✅ Wait for pods to be ready
- ✅ Display access information

### Step 3: Manual Deployment (Alternative)

```bash
cd k8s/monitoring/production

# Deploy Prometheus
kubectl apply -f prometheus-config.yaml
kubectl apply -f prometheus-deployment.yaml
kubectl apply -f prometheus-ingress.yaml

# Deploy Grafana
kubectl apply -f grafana-config.yaml
kubectl apply -f grafana-dashboard-aloochat.yaml
kubectl apply -f grafana-deployment.yaml

# Wait for pods
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n default
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n default
```

### Step 4: Configure DNS

**Get Production Ingress IP:**

```bash
kubectl get svc ingress-nginx-controller -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
# Example output: 144.126.247.64
```

**Add DNS Records in Cloudflare:**

| Type | Name | Content | Proxy Status | TTL |
|------|------|---------|--------------|-----|
| A | `grafana` | `144.126.247.64` | ☁️ DNS only | Auto |
| A | `prometheus` | `144.126.247.64` | ☁️ DNS only | Auto |

**⚠️ CRITICAL:** Must use "DNS only" (gray cloud) for cert-manager to work!

**Verify DNS:**

```bash
nslookup grafana.aloochat.ai
nslookup prometheus.aloochat.ai
# Both should return: 144.126.247.64 (your ingress IP)
# NOT Cloudflare IPs (104.x.x.x or 172.x.x.x)
```

### Step 5: Wait for TLS Certificates

```bash
# Check certificate status
kubectl get certificate -n default

# Should show READY = True after 2-5 minutes:
# NAME                        READY   SECRET                      AGE
# grafana-production-tls      True    grafana-production-tls      5m
# prometheus-production-tls   True    prometheus-production-tls   5m
```

If stuck in False state:

```bash
kubectl describe certificate grafana-production-tls -n default
kubectl describe certificate prometheus-production-tls -n default
```

### Step 6: Access and Verify

**Get Grafana Password:**

```bash
kubectl get secret grafana-credentials -n default -o jsonpath='{.data.admin-password}' | base64 -d
echo
```

**Access via Domain:**
- Grafana: https://grafana.aloochat.ai
- Prometheus: https://prometheus.aloochat.ai

**Access via Port Forward:**

```bash
# Grafana
kubectl port-forward svc/grafana 3000:3000 -n default
# Open: http://localhost:3000

# Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n default
# Open: http://localhost:9090
```

**Verify Dashboards:**
1. Login to Grafana
2. Navigate to **Dashboards → Browse**
3. Check:
   - AlooChat Production - Kubernetes Cluster
   - AlooChat Production - Application Metrics

---

## 📊 Available Dashboards

### 1. Kubernetes Cluster Dashboard
**Metrics:**
- CPU usage per node
- Memory usage per node
- Running pods count
- Pod health status
- Network I/O

### 2. AlooChat Application Dashboard
**Metrics:**
- HTTP request rate
- Response times (p95, p99)
- Rails pod status
- Sidekiq pod status
- Error rates (4xx, 5xx)
- Memory usage per component
- CPU usage per component

---

## 🔒 Security Considerations

### Production Security Checklist

- ✅ **Strong Grafana password** - Changed from default
- ✅ **TLS encryption** - Enabled via cert-manager
- ⚠️ **Prometheus authentication** - Consider adding basic auth
- ⚠️ **Network policies** - Consider restricting access
- ⚠️ **Backup strategy** - Plan for Grafana dashboard backups

### Adding Basic Auth to Prometheus

1. Create htpasswd file:

```bash
htpasswd -c auth prometheus-admin
# Enter password when prompted
```

2. Create Kubernetes secret:

```bash
kubectl create secret generic prometheus-basic-auth \
  --from-file=auth \
  -n default
```

3. Uncomment auth annotations in `prometheus-ingress.yaml`:

```yaml
nginx.ingress.kubernetes.io/auth-type: basic
nginx.ingress.kubernetes.io/auth-secret: prometheus-basic-auth
nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required - AlooChat Prometheus'
```

4. Reapply ingress:

```bash
kubectl apply -f prometheus-ingress.yaml
```

---

## 🛠️ Management Commands

### Check Status

```bash
# Pod status
kubectl get pods -n default -l app=prometheus
kubectl get pods -n default -l app=grafana

# Service status
kubectl get svc -n default -l app=prometheus
kubectl get svc -n default -l app=grafana

# Ingress status
kubectl get ingress -n default prometheus
kubectl get ingress -n default grafana

# Certificate status
kubectl get certificate -n default
```

### View Logs

```bash
# Prometheus logs
kubectl logs -f deployment/prometheus -n default

# Grafana logs
kubectl logs -f deployment/grafana -n default

# Last 100 lines
kubectl logs --tail=100 deployment/prometheus -n default
kubectl logs --tail=100 deployment/grafana -n default
```

### Restart Services

```bash
# Restart Prometheus
kubectl rollout restart deployment/prometheus -n default

# Restart Grafana
kubectl rollout restart deployment/grafana -n default
```

### Check Storage

```bash
# PVC status
kubectl get pvc -n default | grep -E "prometheus|grafana"

# Storage usage
kubectl exec -it deployment/prometheus -n default -- df -h /prometheus
kubectl exec -it deployment/grafana -n default -- df -h /var/lib/grafana
```

### Scale Resources

If you need more resources:

```bash
# Edit deployment
kubectl edit deployment prometheus -n default
kubectl edit deployment grafana -n default

# Or update YAML and reapply
kubectl apply -f prometheus-deployment.yaml
kubectl apply -f grafana-deployment.yaml
```

---

## 🆘 Troubleshooting

### Issue 1: Pods Not Starting

**Check pod status:**

```bash
kubectl get pods -n default -l app=prometheus
kubectl get pods -n default -l app=grafana
```

**Check events:**

```bash
kubectl describe pod <pod-name> -n default
```

**Common causes:**
- Storage class not available
- Insufficient resources
- Image pull errors

### Issue 2: 404 or NGINX Error

**Cause:** Wrong ingress class name

**Solution:**

```bash
# Check ingress class
kubectl get ingressclass

# Update configurations to match
# Edit grafana-deployment.yaml and prometheus-ingress.yaml
# Change ingressClassName to match your production ingress class

# Reapply
kubectl apply -f grafana-deployment.yaml
kubectl apply -f prometheus-ingress.yaml
```

### Issue 3: TLS Certificates Not Ready

**Check certificate status:**

```bash
kubectl describe certificate grafana-production-tls -n default
kubectl describe certificate prometheus-production-tls -n default
```

**Common causes:**
1. DNS pointing to Cloudflare proxy (must be DNS only)
2. Wrong ingress class
3. cert-manager not running

**Solution:**

```bash
# Verify DNS is correct
nslookup grafana.aloochat.ai
# Should return your ingress IP, not Cloudflare IPs

# Check cert-manager
kubectl logs -n cert-manager deployment/cert-manager
```

### Issue 4: Prometheus Permission Errors

**Symptom:** Prometheus crashing with "permission denied"

**Solution:** Already fixed in deployment with security context:

```yaml
securityContext:
  fsGroup: 65534
  runAsUser: 65534
  runAsNonRoot: true
```

If still having issues:

```bash
kubectl delete deployment prometheus -n default
kubectl apply -f prometheus-deployment.yaml
```

### Issue 5: No Metrics in Grafana

**Check Prometheus is scraping:**

1. Port forward Prometheus:
   ```bash
   kubectl port-forward svc/prometheus 9090:9090 -n default
   ```

2. Open http://localhost:9090/targets

3. Verify targets are "UP"

**Check Grafana datasource:**

1. Login to Grafana
2. Go to Configuration → Data Sources → Prometheus
3. Click "Test" - should show "Data source is working"

---

## 📈 Monitoring Best Practices

### 1. Regular Health Checks

```bash
# Weekly check
kubectl get pods -n default -l app=prometheus
kubectl get pods -n default -l app=grafana
kubectl get certificate -n default
```

### 2. Storage Monitoring

```bash
# Check storage usage monthly
kubectl exec -it deployment/prometheus -n default -- df -h /prometheus
```

When storage reaches 80%, consider:
- Reducing retention period
- Increasing storage size
- Archiving old data

### 3. Dashboard Backups

Export Grafana dashboards regularly:
1. Go to Dashboard → Settings → JSON Model
2. Copy JSON
3. Save to version control

### 4. Alert Configuration

Consider setting up alerts for:
- High CPU/Memory usage
- Pod restarts
- Storage reaching capacity
- Certificate expiration

---

## 🔄 Updates and Maintenance

### Updating Prometheus

```bash
# Edit image version in prometheus-deployment.yaml
# Change: image: prom/prometheus:v2.48.0
# To: image: prom/prometheus:v2.XX.0

kubectl apply -f prometheus-deployment.yaml
```

### Updating Grafana

```bash
# Edit image version in grafana-deployment.yaml
# Change: image: grafana/grafana:10.2.0
# To: image: grafana/grafana:10.X.0

kubectl apply -f grafana-deployment.yaml
```

### Updating Dashboards

```bash
# Edit grafana-dashboard-aloochat.yaml
kubectl apply -f grafana-dashboard-aloochat.yaml

# Restart Grafana to reload
kubectl rollout restart deployment/grafana -n default
```

---

## 📞 Support

### If Something Goes Wrong

1. **Check pod logs:**
   ```bash
   kubectl logs -f deployment/prometheus -n default
   kubectl logs -f deployment/grafana -n default
   ```

2. **Check events:**
   ```bash
   kubectl get events -n default --sort-by='.lastTimestamp'
   ```

3. **Verify DNS:**
   ```bash
   nslookup grafana.aloochat.ai
   nslookup prometheus.aloochat.ai
   ```

4. **Check certificates:**
   ```bash
   kubectl describe certificate -n default
   ```

---

## 📝 Deployment Checklist

Before deploying to production:

- [ ] Staging monitoring validated and working
- [ ] Grafana admin password changed
- [ ] Ingress class verified
- [ ] DNS records prepared
- [ ] Backup strategy planned
- [ ] Team notified of deployment
- [ ] Rollback plan documented

After deployment:

- [ ] Pods running successfully
- [ ] DNS configured correctly
- [ ] TLS certificates issued
- [ ] Grafana accessible
- [ ] Prometheus accessible
- [ ] Dashboards showing data
- [ ] No errors in logs
- [ ] Team has access credentials

---

**Deployment Date:** _To be filled_  
**Deployed By:** _To be filled_  
**Status:** ⏳ Ready for Deployment

---

🎉 **Ready to deploy production monitoring!**
