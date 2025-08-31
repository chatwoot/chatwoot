Weave::Core

Lightweight Rails engine providing WeaveSmart Chat (WSC) extensions over Chatwoot core.

Endpoints
- GET /wsc/healthz — basic liveness probe (JSON).
- GET /wsc/api/accounts/:account_id/features — effective features and plan.
- PATCH /wsc/api/accounts/:account_id/features — set per‑feature overrides (admin only).

Notes
- Engine is namespaced under `Weave::Core` and mounted at `/wsc` in the host app.
- Keep new APIs here; document under `swagger/wsc/` and generate the TypeScript SDK for the dashboard.
- Migrations are auto‑appended; run `bin/rails db:migrate` in the host app to create WSC tables.
