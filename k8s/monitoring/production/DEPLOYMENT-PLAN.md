# Production Monitoring Deployment Plan

## 📋 Pre-Deployment Checklist

### Environment Verification
- [ ] Kubernetes cluster access verified
- [ ] Production namespace (`default`) confirmed
- [ ] Ingress controller running and healthy
- [ ] cert-manager installed and operational
- [ ] Storage class `do-block-storage` available
- [ ] Staging monitoring validated (24-48 hours)

### Configuration Review
- [ ] Grafana admin password changed from default
- [ ] Ingress class name verified (`nginx` for production)
- [ ] Domain names confirmed (`grafana.aloochat.ai`, `prometheus.aloochat.ai`)
- [ ] Resource limits appropriate for production load
- [ ] Retention period set (90 days for Prometheus)
- [ ] Storage sizes appropriate (50Gi Prometheus, 20Gi Grafana)

### DNS Preparation
- [ ] Cloudflare access confirmed
- [ ] Production ingress IP obtained
- [ ] DNS records prepared (not yet applied)

### Team Coordination
- [ ] Deployment window scheduled
- [ ] Team notified of deployment
- [ ] Rollback plan documented
- [ ] On-call engineer identified

---

## 🚀 Deployment Steps

### Phase 1: Initial Deployment (15-20 minutes)

#### Step 1: Verify Environment (5 min)

```bash
# Check cluster connection
kubectl cluster-info

# Verify ingress class
kubectl get ingressclass
# Expected: nginx (for production)

# Get ingress IP
kubectl get svc ingress-nginx-controller -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
# Note this IP for DNS configuration
```

**Expected Output:**
- Cluster info displays correctly
- Ingress class `nginx` exists
- Ingress IP: `144.126.247.64` (or your actual IP)

#### Step 2: Update Configuration (5 min)

```bash
cd k8s/monitoring/production

# Update Grafana password
nano grafana-deployment.yaml
# Change line ~22: admin-password: YOUR_STRONG_PASSWORD

# Verify ingress class matches
grep -n "ingressClassName" *.yaml
# Should show: nginx (not nginx-staging)
```

**Verification:**
- [ ] Password changed and saved
- [ ] Ingress class is `nginx`
- [ ] All files reviewed

#### Step 3: Deploy Monitoring Stack (10 min)

```bash
# Run deployment script
./deploy.sh

# Or manual deployment:
kubectl apply -f prometheus-config.yaml
kubectl apply -f prometheus-deployment.yaml
kubectl apply -f prometheus-ingress.yaml
kubectl apply -f grafana-config.yaml
kubectl apply -f grafana-dashboard-aloochat.yaml
kubectl apply -f grafana-deployment.yaml

# Wait for pods
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n default
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n default
```

**Expected Output:**
```
✓ Prometheus configuration deployed
✓ Prometheus deployed
✓ Prometheus ingress deployed
✓ Grafana configuration deployed
✓ Grafana dashboards deployed
✓ Grafana deployed
✓ Prometheus is ready
✓ Grafana is ready
```

**Verification:**
```bash
kubectl get pods -n default -l app=prometheus
kubectl get pods -n default -l app=grafana
# Both should show: Running
```

---

### Phase 2: DNS Configuration (5-10 minutes)

#### Step 4: Configure DNS in Cloudflare

**Add A Records:**

1. **Grafana:**
   - Type: `A`
   - Name: `grafana`
   - Content: `144.126.247.64` (your ingress IP)
   - Proxy status: **DNS only** (gray cloud)
   - TTL: Auto

2. **Prometheus:**
   - Type: `A`
   - Name: `prometheus`
   - Content: `144.126.247.64` (your ingress IP)
   - Proxy status: **DNS only** (gray cloud)
   - TTL: Auto

**Verify DNS Propagation:**

```bash
# Wait 1-2 minutes, then check
nslookup grafana.aloochat.ai
nslookup prometheus.aloochat.ai

# Both should return: 144.126.247.64
# NOT Cloudflare IPs (104.x.x.x or 172.x.x.x)
```

**If DNS shows Cloudflare IPs:**
- Go back to Cloudflare
- Click the orange cloud to change to gray cloud (DNS only)
- Wait 1 minute and check again

---

### Phase 3: TLS Certificate Provisioning (5-10 minutes)

#### Step 5: Wait for Certificates

```bash
# Check certificate status
watch kubectl get certificate -n default

# Expected after 2-5 minutes:
# NAME                        READY   SECRET                      AGE
# grafana-production-tls      True    grafana-production-tls      5m
# prometheus-production-tls   True    prometheus-production-tls   5m
```

**If certificates stuck in False:**

```bash
# Check certificate details
kubectl describe certificate grafana-production-tls -n default
kubectl describe certificate prometheus-production-tls -n default

# Check cert-manager logs
kubectl logs -n cert-manager deployment/cert-manager --tail=50

# Common issues:
# 1. DNS still pointing to Cloudflare proxy
# 2. Ingress class mismatch
# 3. cert-manager not running
```

---

### Phase 4: Verification (10-15 minutes)

#### Step 6: Access and Verify

**Get Grafana Credentials:**

```bash
kubectl get secret grafana-credentials -n default -o jsonpath='{.data.admin-password}' | base64 -d
echo
```

**Access Grafana:**

1. Open: https://grafana.aloochat.ai
2. Login with: `admin` / (password from above)
3. Navigate to **Dashboards → Browse**
4. Verify dashboards exist:
   - AlooChat Production - Kubernetes Cluster
   - AlooChat Production - Application Metrics

**Verify Prometheus:**

1. Open: https://prometheus.aloochat.ai
2. Go to **Status → Targets**
3. Verify targets are being scraped:
   - kubernetes-apiservers: UP
   - kubernetes-nodes: UP
   - kubernetes-pods: UP
   - nginx-ingress: UP

**Check Metrics in Grafana:**

1. Open Kubernetes Cluster dashboard
2. Verify data is showing:
   - CPU Usage gauge
   - Memory Usage gauge
   - Running Pods count

3. Open Application Metrics dashboard
4. Verify data is showing:
   - HTTP request rate
   - Pod status
   - Resource usage

**Verification Checklist:**
- [ ] Grafana accessible via HTTPS
- [ ] Prometheus accessible via HTTPS
- [ ] No certificate warnings
- [ ] Dashboards visible in Grafana
- [ ] Metrics showing in dashboards
- [ ] Prometheus targets are UP
- [ ] No errors in pod logs

---

## 🔍 Post-Deployment Validation

### Immediate Checks (Day 0)

```bash
# 1. Pod health
kubectl get pods -n default -l app=prometheus
kubectl get pods -n default -l app=grafana

# 2. Resource usage
kubectl top pod -n default -l app=prometheus
kubectl top pod -n default -l app=grafana

# 3. Storage usage
kubectl get pvc -n default | grep -E "prometheus|grafana"

# 4. Logs (no errors)
kubectl logs deployment/prometheus -n default --tail=50
kubectl logs deployment/grafana -n default --tail=50

# 5. Ingress status
kubectl get ingress -n default prometheus
kubectl get ingress -n default grafana

# 6. Certificate status
kubectl get certificate -n default
```

### Short-term Monitoring (Week 1)

**Daily Checks:**
- [ ] Day 1: Verify all metrics are being collected
- [ ] Day 2: Check storage usage trends
- [ ] Day 3: Verify dashboards are accurate
- [ ] Day 4: Test alert configurations (if any)
- [ ] Day 5: Review resource usage patterns
- [ ] Day 6: Check for any errors in logs
- [ ] Day 7: Full system health check

**Metrics to Monitor:**
- Prometheus storage usage
- Grafana storage usage
- Pod CPU/Memory usage
- Number of metrics being scraped
- Query performance in Grafana

### Long-term Validation (Month 1)

**Weekly Reviews:**
- Storage growth rate
- Query performance
- Dashboard accuracy
- Resource optimization opportunities

---

## 🚨 Rollback Plan

### If Deployment Fails

**Scenario 1: Pods Not Starting**

```bash
# Delete deployments
kubectl delete deployment prometheus -n default
kubectl delete deployment grafana -n default

# Delete PVCs (if needed - will lose data)
kubectl delete pvc prometheus-storage -n default
kubectl delete pvc grafana-storage -n default

# Review and fix configuration
# Redeploy
```

**Scenario 2: DNS/TLS Issues**

```bash
# Remove DNS records from Cloudflare
# Delete ingresses
kubectl delete ingress prometheus -n default
kubectl delete ingress grafana -n default

# Fix configuration
# Reapply ingresses
kubectl apply -f prometheus-ingress.yaml
kubectl apply -f grafana-deployment.yaml
```

**Scenario 3: Complete Rollback**

```bash
# Delete all monitoring resources
kubectl delete -f grafana-deployment.yaml
kubectl delete -f grafana-dashboard-aloochat.yaml
kubectl delete -f grafana-config.yaml
kubectl delete -f prometheus-ingress.yaml
kubectl delete -f prometheus-deployment.yaml
kubectl delete -f prometheus-config.yaml

# Remove DNS records from Cloudflare
# Review issues and plan redeployment
```

---

## 📊 Success Criteria

### Deployment Successful When:

- ✅ All pods running without restarts
- ✅ Grafana accessible via HTTPS
- ✅ Prometheus accessible via HTTPS
- ✅ TLS certificates valid
- ✅ Dashboards showing live metrics
- ✅ No errors in pod logs
- ✅ Storage properly mounted
- ✅ Prometheus scraping all targets
- ✅ Team can access with credentials
- ✅ DNS resolving correctly

---

## 📝 Deployment Record

**Deployment Information:**

- **Date:** _________________
- **Time:** _________________
- **Deployed By:** _________________
- **Kubernetes Version:** _________________
- **Prometheus Version:** v2.48.0
- **Grafana Version:** v10.2.0

**Environment Details:**

- **Cluster:** Production
- **Namespace:** default
- **Ingress IP:** _________________
- **Storage Class:** do-block-storage

**DNS Configuration:**

- **Grafana Domain:** grafana.aloochat.ai
- **Prometheus Domain:** prometheus.aloochat.ai
- **DNS Provider:** Cloudflare
- **Proxy Status:** DNS only (gray cloud)

**Access Credentials:**

- **Grafana Username:** admin
- **Grafana Password:** (stored in Kubernetes secret)
- **Prometheus Auth:** None (consider adding)

**Verification Results:**

- [ ] Pods running: ___/___
- [ ] Ingresses configured: ___/___
- [ ] Certificates issued: ___/___
- [ ] Dashboards working: ___/___
- [ ] Metrics flowing: Yes / No
- [ ] Team notified: Yes / No

**Issues Encountered:**

_________________
_________________
_________________

**Resolution:**

_________________
_________________
_________________

**Sign-off:**

- **Deployed By:** _________________ Date: _______
- **Verified By:** _________________ Date: _______
- **Approved By:** _________________ Date: _______

---

## 🎯 Next Steps After Deployment

### Immediate (Day 1)
1. ✅ Monitor pod health for first 24 hours
2. ✅ Share access credentials with team
3. ✅ Document any issues encountered
4. ✅ Create team training session

### Short-term (Week 1)
1. ⏳ Configure alerts (if needed)
2. ⏳ Set up dashboard backups
3. ⏳ Review and optimize resource usage
4. ⏳ Add basic auth to Prometheus (recommended)

### Long-term (Month 1)
1. ⏳ Review storage usage and adjust if needed
2. ⏳ Customize dashboards based on team feedback
3. ⏳ Implement backup strategy
4. ⏳ Plan for scaling if needed

---

**Status:** ⏳ Ready for Production Deployment

**Last Updated:** October 23, 2025
