WeaveSmart Chat – Operations

Secrets (GitHub/Environments)
- Railway: RAILWAY_TOKEN, RAILWAY_SERVICE_ID_STAGING, RAILWAY_ENV_ID_STAGING, RAILWAY_SERVICE_ID_PROD, RAILWAY_ENV_ID_PROD
- Database (backup workflow): DATABASE_URL
- Sentry: SENTRY_DSN

Deploy & Migrations
- Staging deploy: .github/workflows/deploy_staging.yml (runs bundle exec rails db:migrate after deploy)
- Production deploy: .github/workflows/deploy_prod.yml (runs migrations after deploy)

Logging & Security
- Lograge JSON: set LOGRAGE_ENABLED=true
- CSP (report-only by default): set WSC_CSP_ENABLED=true, WSC_CSP_REPORT_ONLY=true

Health & Metrics
- Liveness: GET /wsc/healthz
- Prometheus metrics: GET /wsc/metrics

Backups
- Daily pg_dump: .github/workflows/db_backup.yml (requires DATABASE_URL)
- Weekly restore test: .github/workflows/db_restore_test.yml

