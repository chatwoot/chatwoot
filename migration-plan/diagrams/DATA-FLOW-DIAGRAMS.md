# Data Flow Diagrams

## Overview

These diagrams show how data flows through the Rails (current) and TypeScript (target) architectures for different scenarios.

---

## 1. HTTP Request Flow

### Rails (Current)

```mermaid
sequenceDiagram
    participant Client
    participant Nginx
    participant Rack
    participant Router
    participant Controller
    participant Service
    participant Model
    participant DB
    participant Redis

    Client->>Nginx: POST /api/v1/messages
    Nginx->>Rack: Forward request
    Rack->>Rack: Middleware chain (CORS, Auth, etc.)
    Rack->>Router: Route to controller
    Router->>Controller: MessagesController#create
    Controller->>Controller: before_action :authenticate!
    Controller->>Controller: before_action :set_conversation
    Controller->>Service: Messages::CreateService.new(...).perform
    Service->>Model: Message.create!(...)
    Model->>Model: Validations
    Model->>Model: before_save callbacks
    Model->>DB: INSERT INTO messages
    DB-->>Model: Message record
    Model->>Model: after_create callbacks
    Model->>Model: Broadcast event (Wisper)
    Service-->>Controller: message
    Controller->>Redis: Cache conversation metadata
    Controller->>Controller: MessageSerializer.new(message)
    Controller-->>Client: 201 Created + JSON
```

### TypeScript/NestJS (Target)

```mermaid
sequenceDiagram
    participant Client
    participant Nginx
    participant Gateway
    participant Guard
    participant Pipe
    participant Controller
    participant Service
    participant Repository
    participant Entity
    participant DB
    participant Redis
    participant Events

    Client->>Nginx: POST /api/v1/messages
    Nginx->>Gateway: Forward request
    Gateway->>Guard: JwtAuthGuard.canActivate()
    Guard->>Guard: Validate JWT token
    Guard-->>Gateway: user context
    Gateway->>Pipe: ValidationPipe.transform(dto)
    Pipe->>Pipe: Validate CreateMessageDto
    Pipe-->>Gateway: validated data
    Gateway->>Controller: create(@Body() dto, @CurrentUser() user)
    Controller->>Service: messageService.create(dto, user)
    Service->>Repository: messageRepository.create(data)
    Repository->>Entity: new Message(...)
    Entity->>Entity: @BeforeInsert() hooks
    Entity->>Entity: Validations
    Service->>Repository: messageRepository.save(message)
    Repository->>DB: INSERT INTO messages
    DB-->>Repository: Message record
    Repository-->>Service: message
    Service->>Events: eventEmitter.emit('message.created', {message})
    Service->>Redis: Cache conversation metadata
    Service-->>Controller: message
    Controller->>Controller: Interceptor transforms response
    Controller-->>Client: 201 Created + JSON

    Note over Events: Async event handlers triggered
    Events->>Service: NotificationService.handleMessageCreated()
    Events->>Service: ConversationService.updateLastActivity()
```

**Key Differences**:
- NestJS uses Guards instead of before_action filters
- Pipes handle validation (not ActiveRecord)
- EventEmitter replaces Wisper pub/sub
- Interceptors handle response transformation

---

## 2. WebSocket Flow

### Rails ActionCable (Current)

```mermaid
sequenceDiagram
    participant Client
    participant ActionCable
    participant Channel
    participant Redis
    participant Broadcaster
    participant Rails

    Client->>ActionCable: WebSocket connect
    ActionCable->>ActionCable: Authenticate connection
    ActionCable-->>Client: Connection established

    Client->>ActionCable: Subscribe to ConversationChannel {id: 123}
    ActionCable->>Channel: ConversationChannel.subscribed
    Channel->>Channel: Authorize subscription
    Channel->>Redis: Subscribe to conversation:123
    Channel-->>Client: Subscribed

    Note over Rails: Message created via API
    Rails->>Broadcaster: ActionCable.broadcast('conversation:123', data)
    Broadcaster->>Redis: PUBLISH conversation:123
    Redis->>Channel: Receive broadcast
    Channel->>ActionCable: Stream data
    ActionCable-->>Client: Message data

    Client->>ActionCable: Perform action: typing_on
    ActionCable->>Channel: ConversationChannel#typing_on
    Channel->>Redis: PUBLISH conversation:123:typing
    Redis->>Channel: Receive typing event
    Channel-->>Client: Typing indicator
```

### TypeScript Socket.io (Target)

```mermaid
sequenceDiagram
    participant Client
    participant SocketIO
    participant Gateway
    participant Service
    participant Redis
    participant EventEmitter

    Client->>SocketIO: WebSocket connect + auth token
    SocketIO->>Gateway: handleConnection(socket)
    Gateway->>Gateway: Validate JWT token
    Gateway->>Gateway: socket.join('user:456')
    Gateway->>Gateway: socket.join('account:789')
    Gateway-->>Client: Connection established

    Client->>SocketIO: join-conversation {conversationId: 123}
    SocketIO->>Gateway: @SubscribeMessage('join-conversation')
    Gateway->>Service: conversationService.canAccess(user, 123)
    Service-->>Gateway: authorized
    Gateway->>Gateway: socket.join('conversation:123')
    Gateway->>Redis: Add to presence set
    Gateway-->>Client: joined-conversation

    Note over EventEmitter: Message created via API
    EventEmitter->>Gateway: @OnEvent('message.created')
    Gateway->>Gateway: handleMessageCreated({message})
    Gateway->>Redis: Get Socket.io adapter
    Gateway->>SocketIO: io.to('conversation:123').emit('new-message', data)
    SocketIO-->>Client: new-message event

    Client->>SocketIO: typing-on {conversationId: 123}
    SocketIO->>Gateway: @SubscribeMessage('typing-on')
    Gateway->>Redis: Set typing indicator (TTL 5s)
    Gateway->>SocketIO: socket.to('conversation:123').emit('typing', data)
    SocketIO-->>Client: typing indicator
```

**Key Differences**:
- Socket.io uses rooms (not channels)
- Authentication happens at connection time
- Events are more granular (@SubscribeMessage)
- Redis adapter for horizontal scaling
- Built-in presence tracking

---

## 3. Background Job Flow

### Rails Sidekiq (Current)

```mermaid
sequenceDiagram
    participant Rails
    participant Sidekiq
    participant Redis
    participant Worker
    participant External

    Rails->>Rails: SendEmailJob.perform_later(user_id, type)
    Rails->>Sidekiq: Enqueue job
    Sidekiq->>Redis: LPUSH queue:default job_data
    Redis-->>Sidekiq: OK

    Note over Worker: Sidekiq worker polls Redis
    Worker->>Redis: BRPOP queue:default
    Redis-->>Worker: job_data
    Worker->>Worker: Deserialize job
    Worker->>Worker: SendEmailJob.perform(user_id, type)
    Worker->>Worker: Load user from DB
    Worker->>External: Send email via SMTP
    External-->>Worker: Success
    Worker->>Redis: Remove from processing set
    Worker->>Redis: Add to completed set

    Note over Worker: If job fails
    Worker->>Redis: Increment retry count
    Worker->>Redis: Schedule retry (exponential backoff)
```

### TypeScript BullMQ (Target)

```mermaid
sequenceDiagram
    participant Service
    participant Queue
    participant Redis
    participant Processor
    participant Worker
    participant External

    Service->>Queue: emailQueue.add('send', {userId, type})
    Queue->>Queue: Create Job instance
    Queue->>Redis: ZADD bull:email:wait timestamp job_id
    Queue->>Redis: HSET bull:email:jobs:123 data
    Redis-->>Service: Job ID

    Note over Processor: Processor polls Redis
    Processor->>Redis: BRPOPLPUSH bull:email:wait bull:email:active
    Redis-->>Processor: job_id
    Processor->>Redis: HGET bull:email:jobs:123
    Redis-->>Processor: job data
    Processor->>Worker: @Process('send') handleSend(job)
    Worker->>Worker: Load user from DB
    Worker->>External: Send email via SMTP
    External-->>Worker: Success
    Worker-->>Processor: Job complete
    Processor->>Redis: LREM bull:email:active job_id
    Processor->>Redis: ZADD bull:email:completed timestamp job_id

    Note over Processor: If job fails
    Processor->>Worker: Job throws error
    Worker-->>Processor: Error caught
    Processor->>Redis: Increment attempts
    Processor->>Redis: ZADD bull:email:delayed retry_timestamp job_id
    Processor->>Redis: Calculate backoff (exponential)
```

**Key Differences**:
- BullMQ uses sorted sets for priorities
- Better job scheduling (delays, repeatable)
- Built-in job events (progress, completed, failed)
- Better concurrency control
- TypeScript decorators (@Process)

---

## 4. Authentication Flow (Detailed)

### Login Flow

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant AuthService
    participant DB
    participant Redis

    Client->>API: POST /auth/login {email, password}
    API->>AuthService: login(email, password)
    AuthService->>DB: SELECT * FROM users WHERE email = ?
    DB-->>AuthService: user (with hashed password)
    AuthService->>AuthService: bcrypt.compare(password, hash)

    alt Password matches
        AuthService->>AuthService: Generate access token (15 min TTL)
        AuthService->>AuthService: Generate refresh token (7 days TTL)
        AuthService->>Redis: SET refresh:token:abc123 user_id EX 604800
        AuthService->>DB: UPDATE users SET last_sign_in_at = NOW()
        AuthService-->>API: {accessToken, refreshToken, user}
        API-->>Client: 200 OK + tokens
    else Password invalid
        AuthService-->>API: UnauthorizedException
        API-->>Client: 401 Unauthorized
    end
```

### Token Refresh Flow

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant AuthService
    participant Redis
    participant DB

    Note over Client: Access token expired
    Client->>API: POST /auth/refresh {refreshToken}
    API->>AuthService: refreshAccessToken(refreshToken)
    AuthService->>AuthService: Decode refresh token
    AuthService->>Redis: GET refresh:token:abc123

    alt Token valid in Redis
        Redis-->>AuthService: user_id
        AuthService->>DB: SELECT * FROM users WHERE id = ?
        DB-->>AuthService: user
        AuthService->>AuthService: Generate new access token
        AuthService->>AuthService: Generate new refresh token (rotation)
        AuthService->>Redis: DEL refresh:token:abc123
        AuthService->>Redis: SET refresh:token:xyz789 user_id EX 604800
        AuthService-->>API: {accessToken, refreshToken}
        API-->>Client: 200 OK + new tokens
    else Token not found or expired
        AuthService-->>API: UnauthorizedException
        API-->>Client: 401 Unauthorized {error: 'refresh_token_expired'}
        Note over Client: Redirect to login
    end
```

### Logout Flow

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant AuthService
    participant Redis

    Client->>API: POST /auth/logout {refreshToken}
    API->>AuthService: logout(refreshToken)
    AuthService->>Redis: DEL refresh:token:abc123
    Redis-->>AuthService: OK
    AuthService-->>API: Success
    API-->>Client: 200 OK
    Note over Client: Clear local tokens
```

---

## 5. Integration Flow (Example: Facebook Messenger)

### Receiving Message from Facebook

```mermaid
sequenceDiagram
    participant Facebook
    participant Webhook
    participant Queue
    participant Processor
    participant Service
    participant DB
    participant Socket

    Facebook->>Webhook: POST /webhooks/facebook {message}
    Webhook->>Webhook: Verify signature (HMAC-SHA256)

    alt Signature valid
        Webhook->>Queue: Add job to process webhook
        Webhook-->>Facebook: 200 OK (quick response)

        Queue->>Processor: Process webhook job
        Processor->>Service: facebookService.processMessage(data)
        Service->>Service: Find or create contact
        Service->>Service: Find or create conversation
        Service->>Service: Create message
        Service->>DB: INSERT INTO messages
        DB-->>Service: message
        Service->>Socket: Emit 'message.created' event
        Socket-->>Client: Real-time message delivery
        Service->>Service: Check for automation rules
        Service->>Queue: Enqueue notification job
    else Signature invalid
        Webhook-->>Facebook: 401 Unauthorized
    end
```

### Sending Message to Facebook

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant Service
    participant Queue
    participant Processor
    participant Facebook
    participant DB

    Client->>API: POST /api/v1/messages {content, conversationId}
    API->>Service: messageService.create(data)
    Service->>DB: INSERT INTO messages
    DB-->>Service: message
    Service->>Queue: Add Facebook send job
    Service-->>API: message
    API-->>Client: 201 Created

    Queue->>Processor: Process Facebook send job
    Processor->>Processor: Get Facebook credentials
    Processor->>Facebook: POST /me/messages {recipient, message}

    alt Send successful
        Facebook-->>Processor: {message_id}
        Processor->>DB: UPDATE messages SET external_id = ?
        Processor->>Socket: Emit 'message.sent' event
    else Send failed (rate limit)
        Facebook-->>Processor: 429 Too Many Requests
        Processor->>Queue: Retry with exponential backoff
    else Send failed (invalid token)
        Facebook-->>Processor: 401 Unauthorized
        Processor->>DB: UPDATE inbox SET status = 'disconnected'
        Processor->>Socket: Emit 'inbox.disconnected' event
    end
```

---

## 6. Real-time Conversation Flow

### Complete Flow: User Sends Message

```mermaid
sequenceDiagram
    participant User1
    participant API
    participant Service
    participant DB
    participant Events
    participant Socket
    participant User2
    participant Agent

    User1->>API: POST /messages {content: "Hello"}
    API->>Service: messageService.create(...)
    Service->>DB: INSERT message
    DB-->>Service: message

    Service->>Events: emit('message.created', {message})
    Service-->>API: message
    API-->>User1: 201 Created

    par Broadcast to participants
        Events->>Socket: Broadcast to conversation room
        Socket-->>User2: new-message event
        Socket-->>Agent: new-message event
    and Update conversation
        Events->>Service: conversationService.updateLastActivity()
        Service->>DB: UPDATE conversations SET last_activity_at = NOW()
    and Send notifications
        Events->>Queue: Enqueue notification jobs
        Queue->>Processor: Process push notification
        Processor-->>Agent: Push notification
    and Check automation
        Events->>Service: automationService.checkRules(message)
        Service->>Service: No rules match
    end
```

### Complete Flow: Agent Replies

```mermaid
sequenceDiagram
    participant Agent
    participant API
    participant Service
    participant DB
    participant Events
    participant Socket
    participant User
    participant External

    Agent->>API: POST /messages {content: "Hi! How can I help?"}
    API->>Service: messageService.create(...)
    Service->>DB: INSERT message
    DB-->>Service: message

    Service->>Events: emit('message.created', {message})
    Service-->>API: message
    API-->>Agent: 201 Created

    par Deliver to user
        Events->>Socket: Broadcast to conversation room
        Socket-->>User: new-message event (web)
    and Send to external channel
        Events->>Queue: Enqueue Facebook send job
        Queue->>External: Send via Facebook API
        External-->>User: Message in Messenger app
    and Update metrics
        Events->>Service: analyticsService.trackReply()
        Service->>DB: UPDATE metrics
    and Update conversation status
        Events->>Service: conversationService.updateStatus()
        Service->>DB: UPDATE conversations SET status = 'open'
    end
```

---

## 7. Caching Strategy Flow

```mermaid
graph TB
    Request[HTTP Request] --> CheckCache{Check Redis Cache}

    CheckCache -->|Hit| ReturnCached[Return Cached Data]
    CheckCache -->|Miss| QueryDB[Query Database]

    QueryDB --> Transform[Transform Data]
    Transform --> StoreCache[Store in Redis<br/>TTL: 5-60 min]
    StoreCache --> ReturnFresh[Return Fresh Data]

    Update[Data Update Event] --> InvalidateCache[Invalidate Cache Keys]
    InvalidateCache --> Redis[(Redis)]

    Redis --> CheckCache

    style CheckCache fill:#ff9
    style Redis fill:#9f9
```

**Cache Keys**:
```
user:{id}                    → TTL: 15 minutes
conversation:{id}            → TTL: 5 minutes
conversation:{id}:messages   → TTL: 2 minutes
account:{id}:settings        → TTL: 30 minutes
inbox:{id}:config            → TTL: 10 minutes
```

**Invalidation Strategy**:
- On user update → DEL user:{id}
- On message create → DEL conversation:{id}:messages
- On settings change → DEL account:{id}:settings

---

## 8. Error Handling Flow

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant Service
    participant DB
    participant Sentry
    participant Logger

    Client->>API: POST /messages (invalid data)
    API->>Service: messageService.create(invalidData)
    Service->>DB: INSERT message
    DB-->>Service: ValidationError

    Service->>Service: Catch error
    Service->>Logger: logger.warn('Validation failed', {error})
    Service-->>API: throw BadRequestException
    API->>API: Exception Filter catches error
    API->>Logger: Log request context
    API-->>Client: 400 Bad Request {errors: [...]}

    Note over Client: User fixes data and retries

    Client->>API: POST /messages (valid data)
    API->>Service: messageService.create(data)
    Service->>DB: INSERT message
    DB-->>Service: DatabaseError (connection lost)

    Service->>Service: Catch error
    Service->>Sentry: captureException(error)
    Service->>Logger: logger.error('Database error', {error})
    Service-->>API: throw InternalServerErrorException
    API->>API: Exception Filter catches error
    API->>Sentry: Add request context
    API-->>Client: 500 Internal Server Error

    Note over Sentry: Alert sent to team
```

---

## 9. Database Query Optimization

### N+1 Query Problem (Rails)

```ruby
# BAD: N+1 queries
conversations = Conversation.all  # 1 query
conversations.each do |conv|
  puts conv.messages.count        # N queries!
end

# GOOD: Eager loading
conversations = Conversation.includes(:messages)  # 2 queries
conversations.each do |conv|
  puts conv.messages.count
end
```

### N+1 Query Solution (TypeScript)

```typescript
// BAD: N+1 queries
const conversations = await this.conversationRepository.find();
for (const conv of conversations) {
  const count = await this.messageRepository.count({
    where: { conversationId: conv.id }
  });  // N queries!
}

// GOOD: Eager loading
const conversations = await this.conversationRepository.find({
  relations: ['messages']  // 2 queries (with join)
});
for (const conv of conversations) {
  const count = conv.messages.length;
}

// BETTER: Aggregation query
const conversations = await this.conversationRepository
  .createQueryBuilder('conversation')
  .leftJoinAndSelect('conversation.messages', 'message')
  .loadRelationCountAndMap('conversation.messageCount', 'conversation.messages')
  .getMany();  // Single optimized query
```

---

## 10. Migration Dual-Running Architecture

```mermaid
graph TB
    Client[Client Request] --> LB[Load Balancer<br/>Feature Flag: 5%]

    LB -->|95% traffic| Rails[Rails Application]
    LB -->|5% traffic| NestJS[NestJS Application]

    Rails --> RailsService[Rails Services]
    NestJS --> NestService[NestJS Services]

    RailsService --> SharedDB[(Shared PostgreSQL<br/>Database)]
    NestService --> SharedDB

    RailsService --> SharedRedis[(Shared Redis<br/>Cache + Jobs)]
    NestService --> SharedRedis

    Rails --> Sidekiq[Sidekiq Workers]
    NestJS --> BullMQ[BullMQ Workers]

    Sidekiq --> SharedRedis
    BullMQ --> SharedRedis

    Rails --> Monitoring[Prometheus + Grafana]
    NestJS --> Monitoring

    Monitoring --> Alert{Error Rate<br/>Threshold?}
    Alert -->|Too High| Rollback[Instant Rollback<br/>to 100% Rails]
    Alert -->|OK| Increase[Increase to 25%]

    style LB fill:#ff9
    style SharedDB fill:#9f9
    style SharedRedis fill:#9f9
    style Alert fill:#f99
```

**Key Points**:
- Single shared database (no data sync needed)
- Single Redis instance (job coordination)
- Both stacks can write to database
- Feature flags control traffic split
- Instant rollback capability

---

## Summary

These data flow diagrams show:
1. **HTTP Request Flow**: Guards → Pipes → Controllers → Services → Repositories
2. **WebSocket Flow**: Socket.io rooms, Redis adapter, event-driven
3. **Background Jobs**: BullMQ processors, job events, retry logic
4. **Authentication**: JWT tokens, refresh token rotation, Redis session store
5. **Integrations**: Webhook processing, external API calls, error handling
6. **Real-time**: Event-driven architecture with EventEmitter2
7. **Caching**: Redis caching strategy with invalidation
8. **Error Handling**: Structured logging, Sentry integration
9. **Query Optimization**: Avoid N+1 queries with eager loading
10. **Dual-Running**: Blue-green deployment with feature flags

All flows maintain compatibility with Rails during migration phase.

