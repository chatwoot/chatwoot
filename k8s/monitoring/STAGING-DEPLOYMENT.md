# 🎉 Monitoring Stack Deployed Successfully!

## ✅ Deployment Status

Both Prometheus and Grafana are successfully deployed and running in the `chatwoot-staging` namespace.

```bash
✅ Prometheus: Running
✅ Grafana: Running
✅ Persistent Storage: Configured (20Gi + 10Gi)
✅ Ingress: Configured with nginx-staging
✅ TLS Certificates: Provisioned by cert-manager
✅ DNS: Configured in Cloudflare
✅ Access: Available via HTTPS
```

---

## 🌐 Cloudflare DNS Configuration

### IP Address for DNS Records

**Ingress Controller IP (IPv4):** `46.101.69.239`
**Ingress Controller IP (IPv6):** `2a03:b0c0:3:f0:0:1:2b40:0`

### DNS Records to Add in Cloudflare

Add these **A** and **AAAA** records in your Cloudflare DNS:

#### 1. Grafana Staging

| Type | Name | Content | Proxy Status | TTL |
|------|------|---------|--------------|-----|
| A | `grafana-staging` | `46.101.69.239` | DNS only (gray cloud) | Auto |
| AAAA | `grafana-staging` | `2a03:b0c0:3:f0:0:1:2b40:0` | DNS only (gray cloud) | Auto |

**Full Domain:** `grafana-staging.aloochat.ai`

#### 2. Prometheus Staging

| Type | Name | Content | Proxy Status | TTL |
|------|------|---------|--------------|-----|
| A | `prometheus-staging` | `46.101.69.239` | DNS only (gray cloud) | Auto |
| AAAA | `prometheus-staging` | `2a03:b0c0:3:f0:0:1:2b40:0` | DNS only (gray cloud) | Auto |

**Full Domain:** `prometheus-staging.aloochat.ai`

### ⚠️ Important DNS Notes

1. **Proxy Status:** MUST be set to **DNS only** (gray cloud icon) - NOT proxied through Cloudflare
2. **Why?** cert-manager needs direct access to your server to verify domain ownership for Let's Encrypt certificates
3. **After TLS is working:** You can optionally enable Cloudflare proxy (orange cloud)
4. **Common mistake:** If DNS shows Cloudflare IPs (104.x.x.x or 172.x.x.x), the proxy is enabled - turn it off!

---

## 🔐 Access Credentials

### Grafana Login

- **URL (after DNS):** https://grafana-staging.aloochat.ai
- **URL (port-forward):** http://localhost:3000
- **Username:** `admin`
- **Password:** `AlooChat2025!Staging#Secure`

### Prometheus Access

- **URL (after DNS):** https://prometheus-staging.aloochat.ai
- **URL (port-forward):** http://localhost:9090
- **Authentication:** None (consider adding basic auth for production)

---

## 🚀 Access Methods

### Method 1: Port Forward (Immediate Access)

**Grafana:**
```bash
kubectl port-forward svc/grafana 3000:3000 -n chatwoot-staging
# Open: http://localhost:3000
```

**Prometheus:**
```bash
kubectl port-forward svc/prometheus 9090:9090 -n chatwoot-staging
# Open: http://localhost:9090
```

### Method 2: Domain Access (After DNS Configuration)

1. **Add DNS records** in Cloudflare (see above)
2. **Wait 2-5 minutes** for:
   - DNS propagation
   - cert-manager to provision TLS certificates
3. **Access:**
   - Grafana: https://grafana-staging.aloochat.ai
   - Prometheus: https://prometheus-staging.aloochat.ai

---

## 📊 Available Dashboards

Once logged into Grafana, navigate to **Dashboards → Browse**:

### 1. AlooChat Staging - Kubernetes Cluster
- CPU usage per node
- Memory usage per pod
- Running pods count
- Request rates

### 2. AlooChat Staging - Application Metrics
- HTTP request rate
- Response times (p95, p99)
- Rails & Sidekiq pod status
- 5xx error rate
- Memory & CPU usage per component

---

## 🔍 Verify TLS Certificate Status

Check if cert-manager has issued certificates:

```bash
# Check certificate status
kubectl get certificate -n chatwoot-staging

# Should show:
# NAME                      READY   SECRET                    AGE
# grafana-staging-tls       True    grafana-staging-tls       Xm
# prometheus-staging-tls    True    prometheus-staging-tls    Xm
```

If certificates are not ready after 5 minutes:

```bash
# Check certificate details
kubectl describe certificate grafana-staging-tls -n chatwoot-staging
kubectl describe certificate prometheus-staging-tls -n chatwoot-staging

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager
```

---

## 📈 What's Being Monitored

### Kubernetes Infrastructure
- ✅ Node CPU and memory usage
- ✅ Pod status and restarts
- ✅ Persistent volume usage
- ✅ Network traffic

### AlooChat Application
- ✅ Rails application pods
- ✅ Sidekiq worker pods
- ✅ NGINX ingress controller
- ✅ HTTP request metrics
- ✅ Response times and latency
- ✅ Error rates (4xx, 5xx)

### Data Retention
- **Prometheus:** 30 days of metrics
- **Grafana:** Permanent dashboard storage

---

## 🛠️ Useful Commands

### Check Deployment Status
```bash
kubectl get pods -n chatwoot-staging | grep -E "prometheus|grafana"
kubectl get svc -n chatwoot-staging | grep -E "prometheus|grafana"
kubectl get ingress -n chatwoot-staging | grep -E "prometheus|grafana"
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

### Check Storage
```bash
# Check PVC status
kubectl get pvc -n chatwoot-staging | grep -E "prometheus|grafana"

# Check PV usage
kubectl exec -it deployment/prometheus -n chatwoot-staging -- df -h /prometheus
```

### Get Admin Password
```bash
kubectl get secret grafana-credentials -n chatwoot-staging -o jsonpath='{.data.admin-password}' | base64 -d
echo
```

---

## 🎯 Next Steps

### Immediate (Now)
1. ✅ **Add DNS records** in Cloudflare
2. ✅ **Wait 2-5 minutes** for DNS propagation
3. ✅ **Access Grafana** via domain or port-forward
4. ✅ **Verify dashboards** are showing data

### Short-term (24-48 hours)
1. ⏳ **Monitor metrics** to ensure data collection is working
2. ⏳ **Customize dashboards** based on your needs
3. ⏳ **Set up alerts** (optional)
4. ⏳ **Add more metrics** if needed

### Production Deployment
1. ⏳ **Validate staging** works correctly
2. ⏳ **Create production configs** (I'll help with this)
3. ⏳ **Deploy to production** namespace
4. ⏳ **Configure production DNS** (grafana.aloochat.ai, prometheus.aloochat.ai)

---

## 🔒 Security Recommendations

### For Staging (Current)
- ✅ Strong Grafana password set
- ✅ TLS encryption enabled
- ⚠️ Prometheus has no authentication (consider adding)

### For Production (Future)
- 🔐 Add basic auth to Prometheus ingress
- 🔐 Use OAuth/SSO for Grafana
- 🔐 Restrict access by IP if possible
- 🔐 Enable audit logging

---

## 📋 Complete Deployment Process

This section documents the exact steps taken to deploy the monitoring stack successfully.

### Step 1: Environment Verification
```bash
# Checked ingress class name
kubectl get ingressclass
# Result: nginx-staging (not nginx)
```

### Step 2: Configuration Updates
- Updated `grafana-deployment.yaml`: Changed `ingressClassName` from `nginx` to `nginx-staging`
- Updated `prometheus-ingress.yaml`: Changed `ingressClassName` from `nginx` to `nginx-staging`
- Set Grafana admin password to: `AlooChat2025!Staging#Secure`

### Step 3: Prometheus Deployment
```bash
cd k8s/monitoring/staging
kubectl apply -f prometheus-config.yaml
kubectl apply -f prometheus-deployment.yaml
kubectl apply -f prometheus-ingress.yaml
```

**Issue encountered:** Prometheus crashed with permission errors on `/prometheus/queries.active`

**Fix applied:** Added security context to `prometheus-deployment.yaml`:
```yaml
securityContext:
  fsGroup: 65534
  runAsUser: 65534
  runAsNonRoot: true
```

**Resolution:**
```bash
kubectl delete deployment prometheus -n chatwoot-staging
kubectl apply -f prometheus-deployment.yaml
```

### Step 4: Grafana Deployment
```bash
kubectl apply -f grafana-config.yaml
kubectl apply -f grafana-dashboard-aloochat.yaml
kubectl apply -f grafana-deployment.yaml
```

Result: Grafana deployed successfully on first attempt.

### Step 5: DNS Configuration
```bash
# Got ingress IP
kubectl get svc ingress-nginx-staging-controller -n chatwoot-staging -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
# Result: 46.101.69.239
```

Added DNS records in Cloudflare:
- `grafana-staging.aloochat.ai` → `46.101.69.239` (DNS only)
- `prometheus-staging.aloochat.ai` → `46.101.69.239` (DNS only)

**Issue encountered:** Prometheus DNS was initially proxied through Cloudflare (showing 104.x.x.x IPs)

**Fix applied:** Changed Cloudflare proxy status from "Proxied" (orange cloud) to "DNS only" (gray cloud)

**Verification:**
```bash
nslookup grafana-staging.aloochat.ai
# Result: 46.101.69.239 ✅

nslookup prometheus-staging.aloochat.ai  
# Result: 46.101.69.239 ✅ (after fixing proxy)
```

### Step 6: TLS Certificate Provisioning
```bash
# Waited for cert-manager to provision certificates
kubectl get certificate -n chatwoot-staging

# Result after 3-5 minutes:
# grafana-staging-tls      True    grafana-staging-tls      5m
# prometheus-staging-tls   True    prometheus-staging-tls   5m
```

### Step 7: Access Verification
- ✅ Grafana: https://grafana-staging.aloochat.ai (working)
- ✅ Prometheus: https://prometheus-staging.aloochat.ai (working)
- ✅ Dashboards loading with live metrics
- ✅ No errors in pod logs

### Key Lessons Learned

1. **Ingress Class Matters:** Always verify the correct ingress class name for your environment
2. **DNS Proxy Must Be Off:** cert-manager requires direct access (DNS only, not proxied)
3. **Security Context Required:** Prometheus needs proper file permissions via security context
4. **Patience with TLS:** Certificates take 2-5 minutes to provision after DNS is correct

---

## 📞 Support

### If something isn't working:

1. **Check pod status:**
   ```bash
   kubectl get pods -n chatwoot-staging | grep -E "prometheus|grafana"
   ```

2. **Check logs:**
   ```bash
   kubectl logs -f deployment/grafana -n chatwoot-staging
   kubectl logs -f deployment/prometheus -n chatwoot-staging
   ```

3. **Check ingress:**
   ```bash
   kubectl describe ingress grafana -n chatwoot-staging
   kubectl describe ingress prometheus -n chatwoot-staging
   ```

4. **Verify DNS:**
   ```bash
   nslookup grafana-staging.aloochat.ai
   nslookup prometheus-staging.aloochat.ai
   ```

---

## 📝 Deployment Summary

**Deployment Date:** October 23, 2025
**Environment:** Staging (chatwoot-staging namespace)
**Status:** ✅ Successfully Deployed

**Resources Created:**
- 2 Deployments (Prometheus, Grafana)
- 2 Services (Prometheus, Grafana)
- 2 Ingresses (Prometheus, Grafana)
- 2 PersistentVolumeClaims (20Gi + 10Gi)
- 4 ConfigMaps (configs + dashboards)
- 1 Secret (Grafana credentials)
- RBAC resources (ServiceAccount, ClusterRole, ClusterRoleBinding)

**Total Storage:** 30Gi
**Estimated Cost:** ~$3-4/month for storage (DigitalOcean)

---

🎉 **Congratulations! Your monitoring stack is live!**
