# Chatwoot ⇄ GLPI 11 Integration

Two-way integration engine. Conversations and Kanban cards in Chatwoot are
linked to GLPI tickets. Status changes flow both ways.

## Architecture

```
engines/chatwoot_glpi_integration/
├── lib/                              # engine + version
├── app/
│   ├── controllers/                  # connection, ticket_links, webhooks
│   ├── models/                       # Connection, TicketLink
│   ├── services/                     # GlpiClient, CreateTicketService,
│   │                                 # SyncTicketService, InboundWebhookService
│   ├── jobs/                         # SyncTicketJob, ReconcileAllJob
│   └── views/                        # jbuilder JSON
├── config/routes.rb                  # /api/v1/.../glpi/*  +  /webhooks/glpi/:id
├── db/migrate/                       # 2 tables: connections, ticket_links
├── frontend/                         # Vuex + Vue settings panel
└── spec/                             # RSpec + WebMock
```

### Tables

- `chatwoot_glpi_connections` — one per account; OAuth2 credentials (encrypted client_secret), defaults, webhook secret.
- `chatwoot_glpi_ticket_links` — bridge GLPI ticket ⇄ Chatwoot conversation and/or Kanban card.

## Install

### 1. Gemfile

```ruby
gem 'chatwoot_glpi_integration', path: 'engines/chatwoot_glpi_integration'
```

### 2. config/routes.rb

```ruby
mount ChatwootGlpiIntegration::Engine => '/'
```

### 3. Install

```sh
bundle install
bundle exec rails db:migrate
```

### 4. Frontend (optional UI)

In `app/javascript/dashboard/store/index.js`:
```js
import glpi from 'dashboard/modules/glpi/store/glpi';
// modules: { ..., glpi }
```

In `dashboard.routes.js`:
```js
import glpiRoutes from 'dashboard/modules/glpi/routes/glpi.routes';
// children: [ ...glpiRoutes ]
```

Symlink/copy the frontend folder the same way as the Kanban engine.

## GLPI 11 setup

1. Admin → API Clients → New OAuth2 client (`client_credentials`)
2. Save the **client_id** and **client_secret**
3. Configure a webhook to `https://chatwoot.example.com/webhooks/glpi/<account_id>`
   with **HMAC-SHA256** signing using your chosen `webhook_secret`. Header:
   `X-Glpi-Signature: <hex>`

Then in Chatwoot, go to **Settings → Integrations → GLPI** and fill in:
- Base URL: `https://glpi.example.com`
- Client ID / Secret
- Entity ID (default 0)
- Webhook secret

Click **Test connection** — you should see a green check.

## How sync flows

**Outbound: Chatwoot → GLPI**
- Manual: `POST /api/v1/accounts/:id/glpi/tickets` with `{ conversation_id }` or `{ kanban_card_id }`
- Auto (optional): mark a Kanban column as escalation column —
  `board.update!(settings: { glpi_escalation_column_ids: [<col_id>] })`. Moving
  any card into that column creates a GLPI ticket and links it.

**Inbound: GLPI → Chatwoot**
- GLPI webhook hits `/webhooks/glpi/:account_id`. Signature verified.
- `SyncTicketJob` pulls the latest ticket state and, if status is solved/closed,
  resolves the conversation and/or moves the Kanban card to its board's `done`
  column.

**Periodic reconciliation** — for environments where webhooks are unreliable:

```ruby
# config/initializers/sidekiq_cron.rb
Sidekiq::Cron::Job.create(
  name:  'glpi reconcile every 5 minutes',
  cron:  '*/5 * * * *',
  class: 'ChatwootGlpiIntegration::ReconcileAllJob'
)
```

## API endpoints

| Method | Path                                                         | Description |
|--------|--------------------------------------------------------------|-------------|
| GET    | `/api/v1/accounts/:id/glpi/connection`                       | Show connection |
| POST   | `/api/v1/accounts/:id/glpi/connection`                       | Create (admin) |
| PATCH  | `/api/v1/accounts/:id/glpi/connection`                       | Update (admin) |
| POST   | `/api/v1/accounts/:id/glpi/connection/test`                  | Verify credentials |
| DELETE | `/api/v1/accounts/:id/glpi/connection`                       | Remove (admin) |
| GET    | `/api/v1/accounts/:id/glpi/tickets`                          | List ticket links (filter by conv/card) |
| POST   | `/api/v1/accounts/:id/glpi/tickets`                          | Create ticket from conv/card |
| GET    | `/api/v1/accounts/:id/glpi/tickets/:id`                      | Show link |
| DELETE | `/api/v1/accounts/:id/glpi/tickets/:id`                      | Unlink |
| POST   | `/api/v1/accounts/:id/glpi/tickets/:id/sync`                 | Force sync |
| POST   | `/api/v1/accounts/:id/glpi/tickets/reconcile_all`            | Force all |
| POST   | `/webhooks/glpi/:account_id`                                 | GLPI webhook receiver |

## Security

- `client_secret` is encrypted at rest via Rails 7 `encrypts`. Configure
  `config.active_record.encryption.primary_key` per Rails docs.
- Webhook signature verification is HMAC-SHA256, constant-time compare.
- Access tokens cached in `Rails.cache` (50min TTL), never persisted.

## Testing

```sh
bundle exec rspec engines/chatwoot_glpi_integration/spec
```

Uses WebMock to stub GLPI HTTP calls.

## Upstream-merge safety

Same pattern as Kanban: 2 lines in the host (Gemfile + routes), everything else
namespaced under `ChatwootGlpiIntegration::*` with tables prefixed
`chatwoot_glpi_*`. Upstream changes cannot collide.

## License

MIT.
