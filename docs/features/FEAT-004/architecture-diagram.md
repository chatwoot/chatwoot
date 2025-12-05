# WhatsApp Web Provider - Architecture Diagram

## System Architecture Overview

```mermaid
graph TB
    subgraph "CHATWOOT PLATFORM"
        subgraph "FRONTEND (Vue 3)"
            PS[Provider Selection<br/>Whatsapp.vue]
            WM[WhatsappWeb.vue<br/>Configuration Form]
            PS -->|Select Provider| WM
            WM --> VS[Vuex Store<br/>POST /inboxes]
        end

        subgraph "BACKEND (Rails 7.1)"
            VS --> IC[InboxesController#create]
            IC --> CW[Channel::Whatsapp Model]
            CW --> PS_SVC{provider_service}
            PS_SVC -->|whatsapp_cloud| WCS[WhatsappCloudService]
            PS_SVC -->|whatsapp_web| WMS[WhatsappWebService]
            PS_SVC -->|default| W360[Whatsapp360DialogService]

            WH[Webhooks::WhatsappController] --> WEJ[WhatsappEventsJob<br/>Sidekiq]
            WEJ --> IMS{Route by Provider}
            IMS -->|whatsapp_cloud| IMCS[IncomingMessageCloudService]
            IMS -->|whatsapp_web| IMMS[IncomingMessageWebService]
        end
    end

    subgraph "GO WHATSAPP WEB SERVICE"
        API[REST API<br/>Basic Auth]
        WE[Webhook Engine<br/>HMAC SHA256]

        WMS -->|validate_provider_config| API
        WMS -->|send_message| API
        WMS -->|media_url| API
        WE -->|POST webhook| WH
    end

    subgraph "WHATSAPP SERVERS"
        WA[WhatsApp Protocol]
    end

    API <-->|WhatsApp Web Protocol| WA
```

## Message Flow Diagrams

### Outgoing Message Flow

```mermaid
sequenceDiagram
    participant Agent as Chatwoot Agent
    participant UI as Dashboard UI
    participant API as Rails API
    participant Channel as Channel::Whatsapp
    participant Service as WhatsappWebService
    participant GoWA as Go WhatsApp Service
    participant WA as WhatsApp Servers

    Agent->>UI: Types message
    UI->>API: POST /messages
    API->>Channel: Create message
    Channel->>Service: send_message(phone, message)
    Service->>GoWA: POST /send/message<br/>Basic Auth
    GoWA->>WA: Send via WhatsApp Protocol
    WA-->>GoWA: Message ID
    GoWA-->>Service: {message_id: "xxx"}
    Service-->>Channel: message_id
    Channel-->>API: Update message.source_id
    API-->>UI: Message sent
    UI-->>Agent: Show sent status
```

### Incoming Message Flow

```mermaid
sequenceDiagram
    participant Customer as Customer
    participant WA as WhatsApp Servers
    participant GoWA as Go WhatsApp Service
    participant Webhook as Webhooks::WhatsappController
    participant Job as WhatsappEventsJob
    participant Service as IncomingMessageWebService
    participant DB as Database

    Customer->>WA: Sends message
    WA->>GoWA: Message via WhatsApp Protocol
    GoWA->>Webhook: POST /webhooks/whatsapp/:phone<br/>X-Hub-Signature-256
    Webhook->>Webhook: Verify HMAC signature
    alt Signature Valid
        Webhook->>Job: Enqueue job (Sidekiq)
        Job->>Service: perform(params)
        Service->>DB: Find/Create Contact
        Service->>DB: Find/Create Conversation
        Service->>DB: Create Message
        Service->>DB: Update Conversation status
    else Signature Invalid
        Webhook-->>GoWA: 401 Unauthorized
    end
```

### Message Receipt Flow

```mermaid
sequenceDiagram
    participant Customer as Customer
    participant WA as WhatsApp Servers
    participant GoWA as Go WhatsApp Service
    participant Webhook as Webhook Controller
    participant Job as WhatsappEventsJob
    participant Service as IncomingMessageWebService
    participant Conv as Conversation

    Customer->>WA: Opens chat (reads message)
    WA->>GoWA: Receipt event
    GoWA->>Webhook: POST webhook<br/>event: message.ack<br/>receipt_type: read
    Webhook->>Job: Enqueue
    Job->>Service: Process receipt
    Service->>Conv: Update status to "read"
    Service->>Conv: Trigger real-time update
```

## Security Flow

### HMAC Signature Verification

```mermaid
flowchart TD
    A[Webhook Request Received] --> B{Extract Header<br/>X-Hub-Signature-256}
    B -->|Found| C[Get Raw Request Body]
    B -->|Not Found| Z[Return 401 Unauthorized]

    C --> D[Find Channel by phone_number]
    D -->|Found| E{Check Provider}
    D -->|Not Found| Z

    E -->|whatsapp_web| F[Get webhook_verify_token]
    E -->|Other| G[Use default verification]

    F --> H[Calculate HMAC SHA256<br/>hmac = sha256 webhook_verify_token, raw_body]
    H --> I{Compare Signatures<br/>Timing-Safe Equal}

    I -->|Match| J[Enqueue WhatsappEventsJob]
    I -->|No Match| Z

    J --> K[Return 200 OK]
```

## Database Schema

### Channel WhatsApp Table

```mermaid
erDiagram
    CHANNEL_WHATSAPP {
        bigint id PK
        integer account_id FK
        string phone_number UK "Unique, not null"
        string provider "default|whatsapp_cloud|whatsapp_web"
        jsonb provider_config
        jsonb message_templates
        timestamp message_templates_last_updated
        timestamp created_at
        timestamp updated_at
    }

    INBOX {
        bigint id PK
        string channel_type
        bigint channel_id FK
    }

    MESSAGE {
        bigint id PK
        bigint inbox_id FK
        bigint conversation_id FK
        string source_id "WhatsApp message_id"
        text content
    }

    CHANNEL_WHATSAPP ||--o| INBOX : "has_one"
    INBOX ||--o{ MESSAGE : "has_many"
```

### Provider Config Structure for whatsapp_web

```json
{
  "api_base_url": "http://localhost:3000",
  "basic_auth_username": "admin",
  "basic_auth_password": "secret123",
  "webhook_verify_token": "auto_generated_hex_32",
  "phone_number": "+1234567890"
}
```

### Database Files (Go WhatsApp Service)

```
storages/
├── whatsapp.db          # SQLite: Connection state, devices
├── chatstorage.db       # SQLite: Chat history (optional)
└── qrcode/             # QR code images
    └── scan-qr-*.png
```

## Component Interaction Diagram

### Configuration & Login Flow

```mermaid
sequenceDiagram
    participant Admin as Administrator
    participant UI as Chatwoot UI
    participant API as Rails API
    participant Channel as Channel::Whatsapp
    participant Service as WhatsappWebService
    participant GoWA as Go WhatsApp Service
    participant WA as WhatsApp Mobile

    Admin->>UI: Configure WhatsApp Web inbox
    UI->>UI: Validate form fields
    UI->>API: POST /inboxes<br/>{provider: whatsapp_web, config}
    API->>Channel: Create record
    Channel->>Service: validate_provider_config?
    Service->>GoWA: GET /app/devices<br/>Basic Auth
    GoWA-->>Service: {devices: [...]}

    alt Service Connected
        Service-->>Channel: true
        Channel-->>API: Inbox created
        API-->>UI: Success
        UI->>Admin: Show success + login instructions

        Admin->>GoWA: Open http://localhost:3000
        GoWA->>GoWA: Check connection status

        alt Not Connected
            GoWA->>Admin: Show QR Code
            Admin->>WA: Scan QR with WhatsApp
            WA->>GoWA: Authenticate
            GoWA->>GoWA: Store session
        else Already Connected
            GoWA->>Admin: Show connected status
        end
    else Service Not Reachable
        Service-->>Channel: false
        Channel-->>API: Validation error
        API-->>UI: Error: Cannot reach WhatsApp service
    end
```

### Group Event Flow

```mermaid
sequenceDiagram
    participant Customer as Group Member
    participant WA as WhatsApp Servers
    participant GoWA as Go WhatsApp Service
    participant Webhook as Webhook Handler
    participant Job as Background Job
    participant Service as Message Service
    participant Conv as Conversation

    Customer->>WA: Joins/Leaves Group
    WA->>GoWA: Group event
    GoWA->>Webhook: POST webhook<br/>event: group.participants<br/>type: join|leave|promote|demote
    Webhook->>Job: Enqueue
    Job->>Service: Process group event
    Service->>Conv: Log event in conversation
    Service->>Conv: Add system message (optional)
```

## Event Type Processing Matrix

| Event Type | Payload Field | Chatwoot Action | Creates Message? |
|-----------|---------------|-----------------|------------------|
| **Text Message** | `message.text` | Create text message | ✅ Yes |
| **Image Message** | `image.media_path` | Download & attach | ✅ Yes |
| **Video Message** | `video.media_path` | Download & attach | ✅ Yes |
| **Audio Message** | `audio.media_path` | Download & attach | ✅ Yes |
| **Document Message** | `document.media_path` | Download & attach | ✅ Yes |
| **Sticker Message** | `sticker.media_path` | Download & attach | ✅ Yes |
| **Contact Message** | `contact.vcard` | Parse & display | ✅ Yes |
| **Location Message** | `location.{lat,lng}` | Display map | ✅ Yes |
| **Message Delivered** | `receipt_type: delivered` | Update status | ❌ No (update only) |
| **Message Read** | `receipt_type: read` | Update status, show checkmarks | ❌ No (update only) |
| **Message Revoked** | `action: message_revoked` | Mark as deleted | ❌ No (update only) |
| **Message Edited** | `action: message_edited` | Update content | ❌ No (update only) |
| **Reaction** | `reaction.message` | Add reaction | ⚠️ Optional |
| **Group Join** | `type: join` | Log event | ⚠️ Optional |
| **Group Leave** | `type: leave` | Log event | ⚠️ Optional |
| **Group Promote** | `type: promote` | Log event | ⚠️ Optional |
| **Group Demote** | `type: demote` | Log event | ⚠️ Optional |

## Configuration Checklist

### Go WhatsApp Service Setup

- [ ] Service deployed and running
- [ ] Port 3000 exposed (or custom port)
- [ ] Basic Auth configured (`APP_BASIC_AUTH=user:pass`)
- [ ] Webhook URL configured (`WHATSAPP_WEBHOOK=https://chatwoot.domain/webhooks/whatsapp/:phone`)
- [ ] Webhook secret configured (`WHATSAPP_WEBHOOK_SECRET=random_32_char`)
- [ ] FFmpeg installed (for media processing)
- [ ] Storage directory writable (`./storages`)
- [ ] Logged in via QR code or pairing code

### Chatwoot Configuration

- [ ] Feature flag enabled (if using feature flags)
- [ ] Provider added to `Channel::Whatsapp::PROVIDERS`
- [ ] Service class created: `Whatsapp::Providers::WhatsappWebService`
- [ ] Incoming message service created: `Whatsapp::IncomingMessageWebService`
- [ ] Webhook controller updated for HMAC verification
- [ ] Frontend component created: `WhatsappWeb.vue`
- [ ] i18n translations added
- [ ] Routes configured

### Network Configuration

- [ ] Chatwoot accessible from Go WhatsApp Service
- [ ] Webhook URL publicly accessible (or via tunnel for dev)
- [ ] HTTPS configured (production)
- [ ] Firewall rules allow connections
- [ ] DNS configured (if using domain)

## Deployment Patterns

### Pattern 1: Same Server

```mermaid
graph LR
    subgraph "Server (Single Instance)"
        CW[Chatwoot<br/>:3001]
        GW[Go WhatsApp<br/>:3000]
    end

    CW <-->|localhost| GW
    GW -->|WhatsApp Protocol| WA[WhatsApp Servers]
    GW -->|Webhook localhost:3001| CW
```

### Pattern 2: Separate Servers

```mermaid
graph LR
    subgraph "Chatwoot Server"
        CW[Chatwoot<br/>chatwoot.domain:443]
    end

    subgraph "WhatsApp Server"
        GW[Go WhatsApp<br/>whatsapp.domain:3000]
    end

    CW <-->|HTTPS API| GW
    GW -->|WhatsApp Protocol| WA[WhatsApp Servers]
    GW -->|Webhook HTTPS| CW
```

### Pattern 3: Docker Compose

```mermaid
graph TB
    subgraph "Docker Network: whatsapp_network"
        CW[Chatwoot Container<br/>app:3001]
        GW[Go WhatsApp Container<br/>whatsapp:3000]
        DB[(PostgreSQL<br/>db:5432)]
    end

    subgraph "External"
        NX[Nginx Reverse Proxy<br/>:80/:443]
        WA[WhatsApp Servers]
    end

    NX -->|/| CW
    NX -->|/whatsapp-api| GW
    CW -->|http://whatsapp:3000| GW
    GW -->|Webhook http://app:3001| CW
    CW --> DB
    GW -->|WhatsApp Protocol| WA
```

## Error Handling Flow

### Connection Error Handling

```mermaid
flowchart TD
    A[Send Message Request] --> B{Service Available?}

    B -->|Yes| C{Authenticated?}
    B -->|No| E1[Log Error]

    C -->|Yes| D{WhatsApp Connected?}
    C -->|No| E2[Return 401 Unauthorized]

    D -->|Yes| F[Send Message]
    D -->|No| E3[Return Error:<br/>WhatsApp Not Connected]

    F --> G{Success?}
    G -->|Yes| H[Return message_id]
    G -->|No| E4[Parse Error Response]

    E1 --> Z[Show User Error]
    E2 --> Z
    E3 --> Z
    E4 --> Z

    Z --> Y[Suggest Actions:<br/>1. Check service status<br/>2. Verify credentials<br/>3. Check WhatsApp login]
```

### Webhook Error Recovery

```mermaid
flowchart TD
    A[Webhook Received] --> B{Signature Valid?}

    B -->|No| C[Return 401]
    B -->|Yes| D{Channel Active?}

    D -->|No| E[Log Warning<br/>Return 200]
    D -->|Yes| F[Enqueue Job]

    F --> G{Job Processing}
    G -->|Success| H[Return 200]
    G -->|Error| I{Retry Count < 5?}

    I -->|Yes| J[Retry with Backoff]
    I -->|No| K[Log to Dead Letter Queue]

    J --> G
    K --> L[Alert Admin]
```

## Media Handling Flow

```mermaid
sequenceDiagram
    participant Customer as Customer
    participant WA as WhatsApp
    participant GoWA as Go WhatsApp Service
    participant Webhook as Chatwoot Webhook
    participant Service as Message Service
    participant Storage as File Storage

    Customer->>WA: Sends image
    WA->>GoWA: Media message
    GoWA->>GoWA: Download & save<br/>statics/media/xxx.jpg
    GoWA->>Webhook: POST webhook<br/>{image: {media_path: "statics/media/xxx.jpg"}}
    Webhook->>Service: Process
    Service->>GoWA: GET /statics/media/xxx.jpg<br/>Basic Auth
    GoWA-->>Service: [Image Binary]
    Service->>Storage: Upload to ActiveStorage
    Service->>Service: Create Attachment
    Service->>Service: Link to Message
```

## Implementation Phases

### Phase 1: Core Integration (Week 1-2)

```mermaid
gantt
    title WhatsApp Web Provider Implementation
    dateFormat YYYY-MM-DD
    section Backend
    Add Provider to Model          :2024-01-01, 1d
    Create WhatsappWebService     :2024-01-02, 2d
    Implement send_message        :2024-01-04, 2d
    Add HMAC verification         :2024-01-06, 1d
    Create Incoming Message Service:2024-01-07, 3d

    section Frontend
    Create WhatsappWeb.vue        :2024-01-08, 2d
    Add Provider Selection        :2024-01-10, 1d
    Add i18n Translations         :2024-01-11, 1d

    section Testing
    Unit Tests                    :2024-01-12, 2d
    Integration Tests             :2024-01-13, 2d
```

### Phase 2: Advanced Features (Week 3-4)

- Media download optimization
- Group event processing
- Receipt status updates
- Error handling improvements
- Performance optimization

### Phase 3: Production Readiness (Week 5)

- Security audit
- Load testing
- Documentation
- Deployment guide
- Monitoring setup

---

## Related Documentation

- [Implementation Story](docs/features/FEAT-004/implementation-story.md)
- [Creating WhatsApp Inbox Provider Guide](docs/features/FEAT-004/creating-whatsapp-inbox-provider.md)
- [Go WhatsApp Deployment Guide](docs/features/FEAT-004/deployment-guide.md)
- [Webhook Payload Documentation](docs/features/FEAT-004/webhook-payload.md)
- [API Reference](docs/features/FEAT-004/openapi.md)
