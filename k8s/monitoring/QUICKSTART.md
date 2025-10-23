# Quick Start Guide - AlooChat Monitoring

## 🚀 Deploy to Staging (Complete Process)

### Step 1: Verify Ingress Class

First, check your ingress class name:

```bash
kubectl get ingressclass
# Look for the staging ingress class name (e.g., nginx-staging)
```

**Important:** The ingress configurations use `nginx-staging` for staging environment. If your ingress class has a different name, update:
- `staging/grafana-deployment.yaml` (line with `ingressClassName`)
- `staging/prometheus-ingress.yaml` (line with `ingressClassName`)

### Step 2: Update Admin Password

Edit `staging/grafana-deployment.yaml` and change the password:

```bash
# Find this section and change the password:
stringData:
  admin-user: admin
  admin-password: YOUR_SECURE_PASSWORD_HERE  # Change this!
```

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

### Step 4: Configure DNS in Cloudflare

Get your ingress controller IP:

```bash
kubectl get svc ingress-nginx-staging-controller -n chatwoot-staging -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
# Example output: 46.101.69.239
```

Add these DNS records in Cloudflare:

**For Grafana:**
- Type: `A`
- Name: `grafana-staging`
- Content: `YOUR_INGRESS_IP` (e.g., 46.101.69.239)
- Proxy status: **DNS only** (gray cloud) ⚠️ Important!
- TTL: Auto

**For Prometheus:**
- Type: `A`
- Name: `prometheus-staging`
- Content: `YOUR_INGRESS_IP` (e.g., 46.101.69.239)
- Proxy status: **DNS only** (gray cloud) ⚠️ Important!
- TTL: Auto

**Why DNS only?** cert-manager needs direct access to provision Let's Encrypt SSL certificates.

### Step 5: Verify DNS Propagation

```bash
# Check DNS resolution
nslookup grafana-staging.aloochat.ai
nslookup prometheus-staging.aloochat.ai

# Both should return your ingress IP (e.g., 46.101.69.239)
# NOT Cloudflare IPs (104.x.x.x or 172.x.x.x)
```

### Step 6: Wait for TLS Certificates

```bash
# Check certificate status
kubectl get certificate -n chatwoot-staging

# Wait for READY = True (usually 2-5 minutes)
# NAME                     READY   SECRET                   AGE
# grafana-staging-tls      True    grafana-staging-tls      5m
# prometheus-staging-tls   True    prometheus-staging-tls   5m
```

If certificates are not ready after 5 minutes, check:

```bash
kubectl describe certificate grafana-staging-tls -n chatwoot-staging
kubectl describe certificate prometheus-staging-tls -n chatwoot-staging
```

### Step 7: Access Grafana & Prometheus

**Via Domain (Recommended):**
- Grafana: https://grafana-staging.aloochat.ai
- Prometheus: https://prometheus-staging.aloochat.ai

**Via Port Forward (Alternative):**
```bash
# Grafana
kubectl port-forward svc/grafana 3000:3000 -n chatwoot-staging
# Open: http://localhost:3000

# Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n chatwoot-staging
# Open: http://localhost:9090
```

**Grafana Login:**
- Username: `admin`
- Password: Get it with:
  ```bash
  kubectl get secret grafana-credentials -n chatwoot-staging -o jsonpath='{.data.admin-password}' | base64 -d
  ```

### Step 8: View Dashboards

In Grafana, navigate to:
1. **Dashboards** → **Browse**
2. You'll see:
   - **AlooChat Staging - Kubernetes Cluster**
   - **AlooChat Staging - Application Metrics**

## 📊 What You'll Monitor

### Kubernetes Cluster Dashboard
- ✅ CPU usage per node
- ✅ Memory usage per pod
- ✅ Pod health status
- ✅ Request rates

### AlooChat Application Dashboard
- ✅ HTTP request rate
- ✅ Response times (p95, p99)
- ✅ Rails & Sidekiq pod status
- ✅ Error rates (5xx)
- ✅ Memory & CPU usage per component

## 🔧 Common Tasks

### View Prometheus Metrics
```bash
kubectl port-forward svc/prometheus 9090:9090 -n chatwoot-staging
# Open: http://localhost:9090
```

### Check Deployment Status
```bash
kubectl get pods -n chatwoot-staging | grep -E "prometheus|grafana"
```

### View Logs
```bash
# Prometheus logs
kubectl logs -f deployment/prometheus -n chatwoot-staging

# Grafana logs
kubectl logs -f deployment/grafana -n chatwoot-staging
```

### Restart Services
```bash
# Restart Prometheus
kubectl rollout restart deployment/prometheus -n chatwoot-staging

# Restart Grafana
kubectl rollout restart deployment/grafana -n chatwoot-staging
```

## 🌐 External Access (Optional)

To access Grafana via domain:

1. **Update DNS**: Point `grafana-staging.aloochat.ai` to your ingress IP:
   ```bash
   kubectl get svc ingress-nginx-staging-controller -n chatwoot-staging
   ```

2. **Wait for TLS**: cert-manager will auto-provision SSL (2-5 minutes)

3. **Access**: https://grafana-staging.aloochat.ai

## ✅ Verify Everything Works

```bash
# Check all monitoring resources
kubectl get all -n chatwoot-staging -l app=prometheus
kubectl get all -n chatwoot-staging -l app=grafana

# Check storage
kubectl get pvc -n chatwoot-staging | grep -E "prometheus|grafana"

# Check ingress
kubectl get ingress -n chatwoot-staging grafana
```

## 🎯 Next Steps

1. ✅ Deploy to staging (you're here!)
2. ⏳ Monitor for 24-48 hours
3. ⏳ Validate metrics are accurate
4. ⏳ Deploy to production (see README.md)

## 🆘 Troubleshooting

### 404 Not Found or NGINX Error

**Problem:** Getting 404 or NGINX error when accessing domains.

**Solution:** Check ingress class name matches your environment:

```bash
# Check available ingress classes
kubectl get ingressclass

# If you see 'nginx-staging' instead of 'nginx', update:
# - staging/grafana-deployment.yaml (ingressClassName: nginx-staging)
# - staging/prometheus-ingress.yaml (ingressClassName: nginx-staging)

# Reapply the configurations
kubectl apply -f staging/grafana-deployment.yaml
kubectl apply -f staging/prometheus-ingress.yaml
```

### DNS Pointing to Cloudflare IPs

**Problem:** `nslookup` shows Cloudflare IPs (104.x.x.x or 172.x.x.x) instead of your server IP.

**Solution:** In Cloudflare DNS, change proxy status to "DNS only" (gray cloud):

```bash
# Verify DNS is correct
nslookup grafana-staging.aloochat.ai
nslookup prometheus-staging.aloochat.ai

# Should return your ingress IP (e.g., 46.101.69.239)
# NOT Cloudflare proxy IPs
```

### TLS Certificates Not Ready

**Problem:** Certificates stuck in "False" state.

**Common causes:**
1. DNS pointing to Cloudflare proxy (must be DNS only)
2. Wrong ingress class name
3. cert-manager not running

**Solution:**
```bash
# Check certificate status
kubectl describe certificate grafana-staging-tls -n chatwoot-staging

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager

# Verify DNS is pointing directly to your server (not Cloudflare)
nslookup grafana-staging.aloochat.ai
```

### Prometheus Permission Errors

**Problem:** Prometheus crashing with "permission denied" on `/prometheus/queries.active`.

**Solution:** Already fixed in deployment with security context:
```yaml
securityContext:
  fsGroup: 65534
  runAsUser: 65534
  runAsNonRoot: true
```

If still having issues:
```bash
# Delete old deployment and reapply
kubectl delete deployment prometheus -n chatwoot-staging
kubectl apply -f staging/prometheus-deployment.yaml
```

### Grafana shows "No data"
```bash
# Check Prometheus is running
kubectl get pods -n chatwoot-staging -l app=prometheus

# Check datasource in Grafana
# Go to: Configuration > Data Sources > Prometheus > Test
```

### Can't access Grafana via domain
```bash
# Check service
kubectl get svc grafana -n chatwoot-staging

# Check pod status
kubectl get pods -n chatwoot-staging -l app=grafana

# Check logs
kubectl logs -f deployment/grafana -n chatwoot-staging
```

### Storage issues
```bash
# Check PVC status
kubectl get pvc -n chatwoot-staging

# Describe PVC for details
kubectl describe pvc prometheus-storage -n chatwoot-staging
kubectl describe pvc grafana-storage -n chatwoot-staging
```

## 📝 Important Notes

- **Data Retention**: Prometheus keeps 30 days of metrics
- **Storage**: Uses DigitalOcean block storage (20Gi for Prometheus, 10Gi for Grafana)
- **Security**: Change default password immediately!
- **Backups**: Grafana dashboards are stored in PVC (persistent)

## 🎉 Success Criteria

You'll know it's working when:
- ✅ Both Prometheus and Grafana pods are Running
- ✅ You can access Grafana UI
- ✅ Dashboards show live metrics
- ✅ No errors in pod logs
