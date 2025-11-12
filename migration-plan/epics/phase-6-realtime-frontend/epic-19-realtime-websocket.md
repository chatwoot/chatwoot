# Epic 19: Real-Time WebSocket Infrastructure

## Overview
- **Duration**: 1.5 weeks
- **Complexity**: High
- **Dependencies**: Epic 03-08 (models + API)
- **Team Size**: 2-3 engineers
- **Can Parallelize**: No (shared infrastructure)

## Scope: 10 Tasks

### 1. WebSocket Server Setup (2 days)
- Socket.io server configuration
- NestJS WebSocket gateway
- Connection management
- Connection pooling
- Load balancing support

### 2. Authentication (1 day)
- JWT token validation for WebSocket connections
- User/account context extraction
- Connection authorization

### 3. Rooms & Channels (2 days)
- Room management (per conversation, per inbox, per account)
- Channel subscriptions
- Broadcasting to rooms
- Private channels
- Public channels

### 4. Presence Tracking (1 day)
- User online/offline status
- Typing indicators
- Agent availability
- Last seen tracking

### 5. Event System (2 days)
- Event emitters
- Event listeners (migrate 12 Wisper listeners from Rails)
- Event dispatchers
- Redis pub/sub integration for multi-server

### 6. Real-Time Updates (2 days)
- Live message updates
- Conversation updates
- Notification broadcasts
- Inbox updates
- Contact updates
- Agent status updates

### 7. Performance & Scaling (2 days)
- Connection pooling
- Load balancing (sticky sessions)
- Horizontal scaling with Redis adapter
- Connection recovery
- Reconnection logic

### 8. Error Handling (1 day)
- Connection errors
- Message delivery failures
- Graceful degradation

### 9. Monitoring (1 day)
- Connection metrics
- Message throughput
- Room statistics
- Performance monitoring

### 10. Testing (2 days)
- Unit tests for gateway
- Integration tests for events
- Load testing (10k+ concurrent connections)
- Reconnection testing

## Architecture

```typescript
@WebSocketGateway({
  cors: { origin: '*' },
  transports: ['websocket', 'polling'],
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  constructor(
    private jwtService: JwtService,
    private redisService: RedisService,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const token = client.handshake.auth.token;
      const user = await this.validateToken(token);
      
      // Join user-specific room
      client.join(`user:${user.id}`);
      
      // Join account room
      client.join(`account:${user.accountId}`);
      
      // Track presence
      await this.updatePresence(user.id, 'online');
      
      // Broadcast user online
      this.server.to(`account:${user.accountId}`).emit('user:online', {
        userId: user.id,
      });
    } catch (error) {
      client.disconnect();
    }
  }

  async handleDisconnect(client: Socket) {
    // Update presence
    // Broadcast user offline
  }

  @SubscribeMessage('conversation:typing')
  handleTyping(client: Socket, payload: { conversationId: string }) {
    // Broadcast typing indicator
    client.to(`conversation:${payload.conversationId}`).emit('conversation:typing', {
      userId: client.data.user.id,
    });
  }
}
```

## Event Migration from Rails

Migrate 12 Wisper event listeners:
1. ActionCableListener
2. AgentBotListener
3. AutomationRuleListener
4. CampaignListener
5. CsatSurveyListener
6. HookListener
7. InstallationWebhookListener
8. NotificationListener
9. ParticipationListener
10. ReportingEventListener
11. WebhookListener
12. BaseListener

Convert to TypeScript event emitters:

```typescript
@Injectable()
export class ConversationService {
  constructor(private eventEmitter: EventEmitter2) {}

  async createMessage(conversationId: string, content: string) {
    const message = await this.messageRepository.save({
      conversationId,
      content,
    });

    // Emit event
    this.eventEmitter.emit('message.created', {
      message,
      conversationId,
    });

    return message;
  }
}

@Injectable()
export class MessageCreatedListener {
  @OnEvent('message.created')
  async handleMessageCreated(payload: { message: Message; conversationId: string }) {
    // Broadcast to WebSocket clients
    // Trigger notifications
    // Update conversation
  }
}
```

## Redis Pub/Sub for Multi-Server

```typescript
// Redis adapter for Socket.io
import { createAdapter } from '@socket.io/redis-adapter';
import { createClient } from 'redis';

const pubClient = createClient({ url: process.env.REDIS_URL });
const subClient = pubClient.duplicate();

await Promise.all([pubClient.connect(), subClient.connect()]);

io.adapter(createAdapter(pubClient, subClient));
```

## Load Testing Requirements

- ✅ Support 10,000+ concurrent connections
- ✅ Handle 1,000+ messages per second
- ✅ Latency < 50ms for message delivery
- ✅ Graceful degradation under load

## Critical Requirements

### Performance
- Connection pooling
- Efficient broadcasting
- Redis pub/sub for scaling

### Reliability
- Auto-reconnection
- Message delivery guarantees
- Connection recovery

### Security
- JWT token validation
- Room access control
- Rate limiting

## Estimated Time
10 tasks × 8 hours = 80 hours / 2.5 engineers ≈ 1.5 weeks

## Risk: 🟡 HIGH
- Complex state management
- Concurrency challenges
- Performance critical

---

**Status**: 🟡 Ready (after Epic 03-08)
**Rails Files**: `app/channels/`, `app/listeners/`
