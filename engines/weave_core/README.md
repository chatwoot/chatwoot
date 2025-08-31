Weave::Core

Lightweight Rails engine providing WeaveSmart Chat (WSC) extensions over Chatwoot core.

Endpoints
- GET /wsc/healthz — basic liveness probe (JSON).

Notes
- Engine is namespaced under `Weave::Core` and mounted at `/wsc` in the host app.
- Keep new APIs here; document under `swagger/wsc/` and generate the TypeScript SDK for the dashboard.

