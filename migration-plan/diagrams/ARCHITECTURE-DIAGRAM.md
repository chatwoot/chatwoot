# Architecture Diagrams

## Current Rails Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        Browser[Browser/Mobile App]
    end

    subgraph "Rails Application"
        Router[Rails Router]
        Controllers[Controllers<br/>145 files]
        Services[Services<br/>140 files]
        Models[Models<br/>58 files<br/>ActiveRecord]
        Jobs[Background Jobs<br/>69 files<br/>Sidekiq]
        Cable[ActionCable<br/>WebSocket Server]
    end

    subgraph "Data Layer"
        PG[(PostgreSQL<br/>Database)]
        Redis[(Redis<br/>Cache + Jobs)]
    end

    subgraph "External Services"
        Facebook[Facebook/Instagram]
        WhatsApp[WhatsApp]
        Slack[Slack]
        Email[Email SMTP/IMAP]
        Stripe[Stripe]
        AI[OpenAI/Dialogflow]
    end

    Browser --> Router
    Router --> Controllers
    Controllers --> Services
    Services --> Models
    Services --> Jobs
    Models --> PG
    Jobs --> Redis
    Cable --> Redis
    Browser -.WebSocket.-> Cable
    Services --> Facebook
    Services --> WhatsApp
    Services --> Slack
    Services --> Email
    Services --> Stripe
    Services --> AI
```

---

## Target TypeScript/NestJS Architecture

```mermaid
graph TB
    subgraph "Client Layer"
        Browser[Browser/Mobile App]
    end

    subgraph "NestJS Application"
        Gateway[API Gateway<br/>Guards + Interceptors]
        Controllers[Controllers<br/>~145 files]
        Services[Services<br/>~140 files]
        Repositories[Repositories<br/>TypeORM]
        Entities[Entities<br/>58 files<br/>TypeORM]
        Processors[Queue Processors<br/>~69 files<br/>BullMQ]
        SocketGW[Socket.io Gateway<br/>WebSocket Server]
        Events[Event Emitter<br/>Pub/Sub]
    end

    subgraph "Data Layer"
        PG[(PostgreSQL<br/>Same Database)]
        Redis[(Redis<br/>Cache + Queues)]
    end

    subgraph "External Services"
        Facebook[Facebook/Instagram]
        WhatsApp[WhatsApp]
        Slack[Slack]
        Email[Email SMTP/IMAP]
        Stripe[Stripe]
        AI[OpenAI/Dialogflow]
    end

    Browser --> Gateway
    Gateway --> Controllers
    Controllers --> Services
    Services --> Repositories
    Repositories --> Entities
    Entities --> PG
    Services --> Events
    Events --> Processors
    Processors --> Redis
    SocketGW --> Redis
    Browser -.WebSocket.-> SocketGW
    Services --> Facebook
    Services --> WhatsApp
    Services --> Slack
    Services --> Email
    Services --> Stripe
    Services --> AI
```

---

## Migration Transition State (Dual-Running)

```mermaid
graph TB
    subgraph "Client Layer"
        Browser[Browser/Mobile App]
    end

    subgraph "Load Balancer / Feature Flags"
        LB[Nginx/Load Balancer<br/>Feature Flag Router<br/>0% → 5% → 25% → 50% → 100%]
    end

    subgraph "Rails Application (Blue)"
        RailsApp[Rails Server<br/>Existing Production]
        RailsJobs[Sidekiq<br/>Background Jobs]
        RailsCable[ActionCable<br/>WebSockets]
    end

    subgraph "TypeScript Application (Green)"
        NestApp[NestJS Server<br/>New Migration]
        BullMQ[BullMQ<br/>Background Jobs]
        SocketIO[Socket.io<br/>WebSockets]
    end

    subgraph "Shared Data Layer"
        PG[(PostgreSQL<br/>Single Shared Database)]
        Redis[(Redis<br/>Shared Cache)]
    end

    Browser --> LB
    LB -->|95% traffic initially| RailsApp
    LB -->|5% traffic initially| NestApp
    RailsApp --> PG
    NestApp --> PG
    RailsJobs --> Redis
    BullMQ --> Redis
    RailsCable --> Redis
    SocketIO --> Redis

    style LB fill:#ff9,stroke:#333,stroke-width:4px
    style PG fill:#9f9,stroke:#333,stroke-width:2px
    style Redis fill:#9f9,stroke:#333,stroke-width:2px
```

---

## Layered Architecture (NestJS)

```mermaid
graph LR
    subgraph "Presentation Layer"
        Controllers[Controllers<br/>HTTP Endpoints]
        Guards[Guards<br/>Auth + RBAC]
        Interceptors[Interceptors<br/>Transform + Log]
        Pipes[Pipes<br/>Validation]
    end

    subgraph "Business Logic Layer"
        Services[Services<br/>Business Logic]
        Events[Event Emitters<br/>Pub/Sub]
        Policies[Policies<br/>Authorization]
    end

    subgraph "Data Access Layer"
        Repositories[Repositories<br/>Data Access]
        Entities[Entities<br/>TypeORM Models]
        Migrations[Migrations<br/>Schema Changes]
    end

    subgraph "Infrastructure Layer"
        Database[(PostgreSQL)]
        Cache[(Redis)]
        Queue[BullMQ]
        External[External APIs]
    end

    Controllers --> Guards
    Guards --> Pipes
    Pipes --> Services
    Services --> Policies
    Services --> Events
    Services --> Repositories
    Repositories --> Entities
    Entities --> Database
    Services --> Cache
    Services --> Queue
    Services --> External
```

---

## Module Architecture

```mermaid
graph TB
    subgraph "Core Modules"
        AppModule[App Module<br/>Root]
        ConfigModule[Config Module<br/>Environment]
        DatabaseModule[Database Module<br/>TypeORM]
        CacheModule[Cache Module<br/>Redis]
    end

    subgraph "Feature Modules"
        AuthModule[Auth Module<br/>JWT + OAuth]
        UsersModule[Users Module]
        ConversationsModule[Conversations Module]
        MessagesModule[Messages Module]
        ContactsModule[Contacts Module]
        InboxesModule[Inboxes Module]
        TeamsModule[Teams Module]
    end

    subgraph "Integration Modules"
        FacebookModule[Facebook Module]
        WhatsAppModule[WhatsApp Module]
        SlackModule[Slack Module]
        EmailModule[Email Module]
        StripeModule[Stripe Module]
        AIModule[AI/ML Module]
    end

    subgraph "Infrastructure Modules"
        QueueModule[Queue Module<br/>BullMQ]
        WebSocketModule[WebSocket Module<br/>Socket.io]
        LoggingModule[Logging Module<br/>Winston]
        MonitoringModule[Monitoring Module<br/>Prometheus]
    end

    AppModule --> ConfigModule
    AppModule --> DatabaseModule
    AppModule --> CacheModule
    AppModule --> AuthModule
    AppModule --> UsersModule
    AppModule --> ConversationsModule
    AppModule --> MessagesModule
    AppModule --> ContactsModule
    AppModule --> InboxesModule
    AppModule --> TeamsModule
    AppModule --> QueueModule
    AppModule --> WebSocketModule

    ConversationsModule --> FacebookModule
    ConversationsModule --> WhatsAppModule
    ConversationsModule --> SlackModule
    ConversationsModule --> EmailModule

    UsersModule --> StripeModule
    MessagesModule --> AIModule
```

---

## Request Flow Comparison

### Rails Request Flow
```
HTTP Request
    ↓
Rack Middleware (Auth, CORS, etc.)
    ↓
Rails Router (routes.rb)
    ↓
Controller Action (before_action filters)
    ↓
Service Object (business logic)
    ↓
ActiveRecord Model (validations, callbacks)
    ↓
PostgreSQL Database
    ↓
View Serializer (JSON response)
    ↓
HTTP Response
```

### NestJS Request Flow
```
HTTP Request
    ↓
NestJS Middleware (CORS, etc.)
    ↓
Guards (JWT Auth, RBAC)
    ↓
Interceptors (Logging, Timing)
    ↓
Pipes (Validation, Transformation)
    ↓
Controller Method (route handler)
    ↓
Service Method (business logic)
    ↓
Repository (data access)
    ↓
TypeORM Entity (validations, hooks)
    ↓
PostgreSQL Database
    ↓
Interceptor (Response transformation)
    ↓
HTTP Response
```

---

## WebSocket Architecture

### Rails ActionCable
```mermaid
graph LR
    Client[Client] -->|WebSocket| Cable[ActionCable Server]
    Cable --> Redis[(Redis<br/>Pub/Sub)]
    Cable --> Channels[Channels<br/>ConversationChannel<br/>NotificationChannel]
    Channels --> Redis
```

### NestJS Socket.io
```mermaid
graph LR
    Client[Client] -->|WebSocket| Gateway[Socket.io Gateway]
    Gateway --> Redis[(Redis<br/>Adapter)]
    Gateway --> Rooms[Rooms<br/>conversation:123<br/>user:456]
    Gateway --> Events[Event Handlers<br/>@SubscribeMessage]
    Events --> Services[Services]
    Services --> EventEmitter[Event Emitter]
    EventEmitter --> Gateway
```

---

## Background Jobs Architecture

### Rails Sidekiq
```mermaid
graph LR
    Service[Service] -->|perform_later| Job[Job Class<br/>ApplicationJob]
    Job --> Redis[(Redis<br/>Job Queue)]
    Redis --> Sidekiq[Sidekiq Worker<br/>Processes]
    Sidekiq --> Execute[Execute Job<br/>perform method]
```

### NestJS BullMQ
```mermaid
graph LR
    Service[Service] -->|queue.add| Queue[BullMQ Queue]
    Queue --> Redis[(Redis<br/>Job Storage)]
    Redis --> Processor[Queue Processor<br/>@Process decorator]
    Processor --> Handle[Handle Job<br/>async method]
    Handle --> Events[Job Events<br/>completed, failed]
```

---

## Authentication Flow

```mermaid
sequenceDiagram
    participant C as Client
    participant API as NestJS API
    participant Auth as Auth Service
    participant DB as PostgreSQL
    participant Redis as Redis Cache

    C->>API: POST /auth/login {email, password}
    API->>Auth: validateUser(email, password)
    Auth->>DB: findUser(email)
    DB-->>Auth: user data
    Auth->>Auth: bcrypt.compare(password)
    Auth->>Auth: generateTokens(user)
    Auth->>Redis: storeRefreshToken(token, userId)
    Auth-->>API: {accessToken, refreshToken}
    API-->>C: 200 OK + tokens

    Note over C: Store tokens

    C->>API: GET /conversations (Bearer accessToken)
    API->>Auth: validateToken(accessToken)
    Auth->>Auth: jwt.verify(token)
    Auth-->>API: user context
    API->>API: handle request
    API-->>C: 200 OK + data

    Note over C: Access token expires

    C->>API: POST /auth/refresh {refreshToken}
    API->>Auth: refreshAccessToken(token)
    Auth->>Redis: validateRefreshToken(token)
    Redis-->>Auth: userId
    Auth->>DB: findUser(userId)
    Auth->>Auth: generateNewTokens(user)
    Auth->>Redis: rotateRefreshToken(old, new)
    Auth-->>API: {accessToken, refreshToken}
    API-->>C: 200 OK + new tokens
```

---

## Deployment Architecture

```mermaid
graph TB
    subgraph "Production Environment"
        LB[Load Balancer<br/>Nginx + Feature Flags]

        subgraph "Blue Environment (Rails)"
            Rails1[Rails Instance 1]
            Rails2[Rails Instance 2]
            Rails3[Rails Instance 3]
            Sidekiq1[Sidekiq Worker Pool]
        end

        subgraph "Green Environment (NestJS)"
            Nest1[NestJS Instance 1]
            Nest2[NestJS Instance 2]
            Nest3[NestJS Instance 3]
            Bull1[BullMQ Worker Pool]
        end

        subgraph "Data Layer"
            PG_Primary[(PostgreSQL<br/>Primary)]
            PG_Replica[(PostgreSQL<br/>Read Replica)]
            Redis_Primary[(Redis<br/>Primary)]
            Redis_Replica[(Redis<br/>Replica)]
        end

        subgraph "Monitoring"
            Prometheus[Prometheus<br/>Metrics]
            Grafana[Grafana<br/>Dashboards]
            Sentry[Sentry<br/>Error Tracking]
        end
    end

    LB --> Rails1
    LB --> Rails2
    LB --> Rails3
    LB --> Nest1
    LB --> Nest2
    LB --> Nest3

    Rails1 --> PG_Primary
    Rails2 --> PG_Replica
    Rails3 --> PG_Replica
    Nest1 --> PG_Primary
    Nest2 --> PG_Replica
    Nest3 --> PG_Replica

    Rails1 --> Redis_Primary
    Nest1 --> Redis_Primary
    Sidekiq1 --> Redis_Primary
    Bull1 --> Redis_Primary

    Rails1 --> Prometheus
    Nest1 --> Prometheus
    Prometheus --> Grafana
    Rails1 --> Sentry
    Nest1 --> Sentry
```

---

## Data Migration Strategy

```mermaid
graph TD
    Start[Start Migration] --> Phase1[Phase 1: Setup<br/>Infrastructure + Tests]
    Phase1 --> Phase2[Phase 2: Data Layer<br/>58 Models + TypeORM]
    Phase2 --> Phase3[Phase 3: API Layer<br/>~145 Controllers]
    Phase3 --> Phase4[Phase 4: Auth + Jobs<br/>Security + ~69 Jobs]
    Phase4 --> Phase5[Phase 5: Integrations<br/>14 Third-party APIs]
    Phase5 --> Phase6[Phase 6: Real-time<br/>WebSockets + Frontend]
    Phase6 --> Phase7[Phase 7: Deployment<br/>Cutover + Monitoring]

    Phase7 --> Traffic5[5% Traffic to TS]
    Traffic5 --> Monitor5{Monitor<br/>24-48h<br/>OK?}
    Monitor5 -->|Issues| Rollback1[Rollback to Rails]
    Monitor5 -->|Success| Traffic25[25% Traffic to TS]

    Traffic25 --> Monitor25{Monitor<br/>48-72h<br/>OK?}
    Monitor25 -->|Issues| Rollback2[Rollback to Rails]
    Monitor25 -->|Success| Traffic50[50% Traffic to TS]

    Traffic50 --> Monitor50{Monitor<br/>1 week<br/>OK?}
    Monitor50 -->|Issues| Rollback3[Rollback to Rails]
    Monitor50 -->|Success| Traffic100[100% Traffic to TS]

    Traffic100 --> Monitor100{Monitor<br/>2 weeks<br/>OK?}
    Monitor100 -->|Issues| Rollback4[Rollback to Rails]
    Monitor100 -->|Success| Deprecate[Deprecate Rails<br/>Keep as backup 1 month]

    Deprecate --> Complete[Migration Complete]

    style Start fill:#9f9
    style Complete fill:#9f9
    style Rollback1 fill:#f99
    style Rollback2 fill:#f99
    style Rollback3 fill:#f99
    style Rollback4 fill:#f99
```

---

## Legend

- **Solid lines**: Synchronous calls
- **Dashed lines**: Asynchronous/WebSocket connections
- **Blue boxes**: Current Rails components
- **Green boxes**: Target TypeScript components
- **Yellow boxes**: Transition/routing components
- **Cylinders**: Data stores (databases, caches)
- **Rectangles**: Services, modules, components

