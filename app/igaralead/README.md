# IgaraLead Extensions for Nexus (Chatwoot fork)

Custom code placed in standard Rails directories under `igaralead/` and `baileys/`
subdirectories so Zeitwerk autoloads them and upstream merge stays clean.

## Directory Layout

```
app/
├── controllers/
│   ├── concerns/igaralead/
│   │   ├── client_scopable.rb              # Validates client_slug against account
│   │   ├── omniauth_callbacks_extension.rb # Hub OAuth callback handling
│   │   └── sessions_extension.rb           # Hub subscription verification on login
│   └── igaralead/
│       ├── webhooks_controller.rb          # Hub webhook receiver
│       ├── metrics_controller.rb           # Metrics API for Hub dashboard
│       ├── baileys_webhooks_controller.rb  # Baileys sidecar webhooks
│       └── baileys_sessions_controller.rb  # QR code & session management API
├── services/
│   ├── igaralead/
│   │   ├── hub_client.rb                   # HTTP client for Hub API
│   │   ├── hub_token_validator.rb          # JWT/JWKS token validation
│   │   ├── hub_settings_service.rb         # Fetch/cache org settings from Hub
│   │   └── contact_sync_service.rb         # Bidirectional contact sync
│   └── baileys/
│       ├── provider_service.rb             # Communicates with Baileys sidecar
│       ├── incoming_message_service.rb     # Process incoming WhatsApp messages
│       └── send_on_baileys_service.rb      # Send outgoing messages
├── models/channel/
│   └── baileys_whatsapp.rb                 # Channel::BaileysWhatsapp model
├── igaralead/
│   ├── README.md                           # This file
│   └── docs/global_configs_migration.md    # Configuration migration notes
config/
├── initializers/igaralead.rb               # Prepends + OmniAuth strategy require
└── routes/igaralead.rb                     # Top-level IgaraLead routes (draw file)
lib/omniauth/strategies/igarahub.rb         # Custom OmniAuth OAuth2 strategy
db/migrate/
├── 20260312000001_add_hub_fields_...rb     # hub_id fields on users/contacts/accounts
└── 20260312000002_create_channel_baileys...rb
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `HUB_API_URL` | Yes | Hub API base URL |
| `HUB_API_KEY` | Yes | API key for Hub communication |
| `HUB_JWKS_URL` | Yes | Hub JWKS endpoint for token verification |
| `HUB_WEBHOOK_SECRET` | No | HMAC secret for webhook signature validation |
| `HUB_OAUTH_CLIENT_ID` | For OAuth | Hub OAuth2 client ID |
| `HUB_OAUTH_CLIENT_SECRET` | For OAuth | Hub OAuth2 client secret |
| `HUB_URL` | For OAuth | Hub base URL for OAuth flow |
| `HUB_METRICS_API_KEY` | Yes | API key for metrics endpoint |
| `BAILEYS_SIDECAR_URL` | For WhatsApp | Baileys Node.js sidecar URL |
| `BAILEYS_SIDECAR_API_KEY` | For WhatsApp | API key for sidecar communication |

## Routes Added

- `POST /webhooks/hub` → Hub event webhooks
- `GET /igaralead/metrics/:client_slug` → Metrics for Hub dashboard
- `POST /webhooks/baileys/message` → Incoming WhatsApp messages from Baileys
- `POST /webhooks/baileys/status` → Message status updates from Baileys
- `POST /webhooks/baileys/qr` → QR code events from Baileys
- `POST /webhooks/baileys/connection` → Connection state changes from Baileys
- `POST /api/v1/accounts/:id/inboxes/:id/baileys_qr_code` → Request QR code
- `GET /api/v1/accounts/:id/inboxes/:id/baileys_status` → Session status
- `POST /api/v1/accounts/:id/inboxes/:id/baileys_disconnect` → Disconnect session
