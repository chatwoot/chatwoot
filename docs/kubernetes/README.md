# Despliegue de Chatwoot en Kubernetes

Manifests para levantar Chatwoot (Rails + Sidekiq + PostgreSQL + Redis) en Kubernetes.

## Requisitos

- Cluster Kubernetes 1.19+
- `kubectl` configurado
- Imagen: `chatwoot/chatwoot:latest` (oficial) **o tu propia imagen** (recomendado para branding Albatros y seed)
- PostgreSQL 16 con pgvector (incluido en los manifests)

## Construir tu propia imagen (recomendado)

Para incluir tu código (Albatros en `config/installation_config.yml`, cuenta "Albatros" en el seed), genera la imagen desde este repo:

```bash
# Desde la raíz del repo
docker build -f docker/Dockerfile -t TU_REGISTRY/chatwoot-albatros:latest .

# Ejemplo Docker Hub
docker build -f docker/Dockerfile -t midockerhub/chatwoot-albatros:latest .
docker push midockerhub/chatwoot-albatros:latest

# Ejemplo GCR
docker build -f docker/Dockerfile -t gcr.io/MI_PROYECTO/chatwoot-albatros:latest .
docker push gcr.io/MI_PROYECTO/chatwoot-albatros:latest
```

Luego en los manifests cambia `chatwoot/chatwoot:latest` por tu imagen en:
- `migration-job.yaml` (contenedor `migrate`)
- `rails-deployment.yaml` (contenedor `web`)
- `sidekiq-deployment.yaml` (contenedor `worker`)

O con sed (reemplaza `TU_REGISTRY/chatwoot-albatros:latest`):

```bash
sed -i '' 's|chatwoot/chatwoot:latest|TU_REGISTRY/chatwoot-albatros:latest|g' \
  migration-job.yaml rails-deployment.yaml sidekiq-deployment.yaml
```

Si usas solo la imagen oficial, la app funciona pero no incluye branding Albatros ni el seed con la cuenta "Albatros".

## Orden de aplicación

Aplica en este orden (los nombres de recursos asumen namespace `chatwoot`):

```bash
# 1. Namespace
kubectl apply -f namespace.yaml

# 2. Secret y ConfigMap (edita secret.yaml con valores reales antes)
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

# 3. PostgreSQL y Redis
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-statefulset.yaml
kubectl apply -f redis-statefulset.yaml

# 4. Esperar a que Postgres y Redis estén listos
kubectl wait --for=condition=ready pod -l app=postgres -n chatwoot --timeout=120s
kubectl wait --for=condition=ready pod -l app=redis -n chatwoot --timeout=60s

# 5. Job de migración (crea esquema y cuenta Albatros en primera ejecución)
kubectl apply -f migration-job.yaml
kubectl wait --for=condition=complete job/chatwoot-migrate -n chatwoot --timeout=600s

# 6. Rails y Sidekiq
kubectl apply -f rails-deployment.yaml
kubectl apply -f sidekiq-deployment.yaml

# 7. Ingress (ajusta host y TLS)
kubectl apply -f ingress.yaml
```

Aplicar todo el directorio de una vez (respeta dependencias si el cluster ya existe):

```bash
kubectl apply -f docs/kubernetes/
```

## Antes del primer deploy

1. **Editar `configmap.yaml`**
   - `FRONTEND_URL`: tu URL pública (ej. `https://chat.tu-dominio.com`)
   - `MAILER_SENDER_EMAIL`, `SMTP_*`, `MAILER_INBOUND_EMAIL_DOMAIN` según tu correo

2. **Editar `secret.yaml`** (usa `stringData` con valores en claro o genera Secret aparte)
   - `SECRET_KEY_BASE`: `bundle exec rake secret`
   - `POSTGRES_PASSWORD` y `POSTGRES_USERNAME` (coinciden con el usuario que crea Postgres)
   - `REDIS_PASSWORD` y `REDIS_URL`: `redis://:TU_PASSWORD@redis:6379`
   - `SMTP_USERNAME` y `SMTP_PASSWORD`
   - Claves de encriptación: `bundle exec rails db:encryption:init`

3. **Editar `ingress.yaml`**
   - `host`: mismo que `FRONTEND_URL` (sin `https://`)
   - Descomentar `tls` y configurar cert-manager u otro issuer si usas HTTPS

## Estructura de recursos

| Archivo | Recursos |
|---------|----------|
| `namespace.yaml` | Namespace `chatwoot` |
| `configmap.yaml` | ConfigMap con variables no sensibles |
| `secret.yaml` | Secret (plantilla; rellenar con valores reales) |
| `postgres-pvc.yaml` | PVC para datos de PostgreSQL |
| `postgres-statefulset.yaml` | StatefulSet + Service de PostgreSQL |
| `redis-statefulset.yaml` | PVC + StatefulSet + Service de Redis |
| `migration-job.yaml` | Job de migración + PVC para storage de Rails |
| `rails-deployment.yaml` | Deployment + Service de la app (puerto 3000) |
| `sidekiq-deployment.yaml` | Deployment de Sidekiq |
| `ingress.yaml` | Ingress (HTTPS opcional) |

## Storage

- **Postgres:** PVC `postgres-data` (10Gi), ReadWriteOnce.
- **Redis:** PVC `redis-data` (2Gi), ReadWriteOnce.
- **Rails (archivos subidos):** PVC `chatwoot-storage` (5Gi), ReadWriteOnce. El deployment de Rails está con **1 réplica** para poder usar ReadWriteOnce. Para escalar a más réplicas de web necesitas:
  - Un volumen ReadWriteMany (NFS, EFS, etc.) y cambiar el PVC, o
  - Usar `ACTIVE_STORAGE_SERVICE=amazon` / `s3_compatible` en el ConfigMap y quitar el volumen de storage del deployment.

## Escalado

```bash
# Más réplicas web (solo si usas storage ReadWriteMany o S3)
kubectl scale deployment chatwoot-web -n chatwoot --replicas=2

# Más workers Sidekiq
kubectl scale deployment chatwoot-worker -n chatwoot --replicas=2
```

## Comandos útiles

```bash
# Logs de la app
kubectl logs -f deployment/chatwoot-web -n chatwoot

# Logs de Sidekiq
kubectl logs -f deployment/chatwoot-worker -n chatwoot

# Estado del job de migración
kubectl get job chatwoot-migrate -n chatwoot
kubectl logs job/chatwoot-migrate -n chatwoot -f

# Reiniciar despliegue tras cambiar ConfigMap/Secret
kubectl rollout restart deployment/chatwoot-web deployment/chatwoot-worker -n chatwoot
```

## Referencia de variables

Ver [KUBERNETES.md](../KUBERNETES.md) para la lista completa de variables de entorno y opciones de almacenamiento (S3, etc.).

## CI/CD: Build y deploy automático (Albatros)

El flujo es el mismo que en **bot_ave**: al hacer push a la rama `main` (o disparo manual), GitHub Actions:

1. Construye la imagen con `docker/Dockerfile`
2. La sube a DigitalOcean Container Registry (`registry.digitalocean.com/albatros-repository/chatwoot`)
3. Clona el repo **k8-argoCD-kustomize**, actualiza el tag en `running/manifests/chatwoot/apps/chatwoot/overlays/production/kustomization.yaml` y hace push

**Workflow:** `.github/workflows/deploy_chatwoot_albatros.yaml`

**Secrets en el repo Chatwoot (Settings → Secrets and variables → Actions):**

| Secret | Uso |
|--------|-----|
| `DOCKER_REGISTRY_DO` | Registry base, ej. `registry.digitalocean.com/albatros-repository` |
| `DIGITALOCEAN_ACCESS_TOKEN` | Para `doctl registry login` |
| `DEV_OPS_ADMIN_TOKEN` | Token de GitHub con permiso de push al repo k8-argoCD-kustomize |

Tras el push, ArgoCD sincroniza y despliega la nueva imagen en el namespace `chatwoot`.
