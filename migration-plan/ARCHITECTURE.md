# Architecture Decisions & Rationale

## Technology Stack Decisions

### Backend Framework: NestJS

**Decision**: Use NestJS instead of plain Express

**Rationale**:
- ✅ TypeScript-first (not bolted on)
- ✅ Dependency injection (like Rails)
- ✅ Decorator-based (similar to Rails)
- ✅ Modular architecture
- ✅ Built-in support for testing, validation, documentation
- ✅ Great for large applications
- ✅ Active community and good documentation

**Alternatives Considered**:
- Express + TypeScript: Too manual, less structure
- Fastify: Fewer features out-of-box
- AdonisJS: Less mature ecosystem

---

### ORM: TypeORM

**Decision**: Use TypeORM instead of Prisma

**Rationale**:
- ✅ Decorator-based (closer to ActiveRecord)
- ✅ Similar patterns to Rails (callbacks, hooks)
- ✅ Good migration support
- ✅ Active Record AND Data Mapper patterns
- ✅ Works well with NestJS

**Alternatives Considered**:
- Prisma: Better DX but different patterns, requires code generation
- Sequelize: Older, less TypeScript-friendly

---

### Background Jobs: BullMQ

**Decision**: Use BullMQ instead of alternatives

**Rationale**:
- ✅ Redis-based (like Sidekiq)
- ✅ Job priorities
- ✅ Retry logic
- ✅ Cron jobs
- ✅ UI dashboard (Bull Board)
- ✅ TypeScript support
- ✅ Good performance

**Alternatives Considered**:
- Bee-Queue: Simpler but fewer features
- Agenda: MongoDB-based (we use PostgreSQL)

---

### WebSockets: Socket.io

**Decision**: Use Socket.io instead of native WebSockets

**Rationale**:
- ✅ Rooms and namespaces built-in
- ✅ Fallback to long-polling
- ✅ Client libraries for all platforms
- ✅ Wide adoption
- ✅ Good documentation
- ✅ Redis adapter for scaling

**Alternatives Considered**:
- Native WebSocket: More manual setup
- ws: Lower-level, less features

---

### Testing: Vitest

**Decision**: Use Vitest instead of Jest

**Rationale**:
- ✅ Faster (Vite-powered)
- ✅ Native ESM support
- ✅ Jest-compatible API (easy migration)
- ✅ Better TypeScript support
- ✅ Watch mode performance

**Alternatives Considered**:
- Jest: Slower, older
- Mocha + Chai: More setup needed

---

## Architecture Patterns

### Layered Architecture

```
Controllers (HTTP layer)
    ↓
Services (Business logic)
    ↓
Repositories (Data access)
    ↓
Database
```

**Rationale**:
- Clear separation of concerns
- Easy to test each layer
- Matches NestJS patterns
- Similar to Rails MVC

---

### Dependency Injection

**Decision**: Use NestJS DI container

**Rationale**:
- Easier testing (mock dependencies)
- Loose coupling
- Cleaner code
- Automatic lifecycle management

---

### Event-Driven Architecture

**Decision**: Use EventEmitter2 for events

**Rationale**:
- Replaces Rails Wisper pub/sub
- Decouples components
- Easy to add listeners
- Testable

**Pattern**:
```typescript
// Service emits event
this.eventEmitter.emit('message.created', { message });

// Listener handles event
@OnEvent('message.created')
async handleMessageCreated(payload) {
  // Send notification, update conversation, etc.
}
```

---

## Database Strategy

### Schema Compatibility

**Decision**: Use existing PostgreSQL schema (no data migration)

**Rationale**:
- Zero downtime
- No data migration risk
- Rails and TypeScript share database during migration
- Gradual cutover possible

**Implementation**:
- TypeORM entities match Rails schema exactly
- Use Rails naming conventions (snake_case)
- Keep table names same (plural)

---

## Security Decisions

### Authentication: JWT

**Decision**: Use JWT tokens (access + refresh)

**Rationale**:
- Stateless
- Scalable
- Works with Rails during migration
- Industry standard

**Token Strategy**:
- Access token: 15 minutes (short-lived)
- Refresh token: 7 days (long-lived)
- Token rotation on refresh

---

### Authorization: Custom Policy System

**Decision**: Build custom (inspired by Pundit)

**Rationale**:
- Full control
- Matches Rails Pundit exactly
- Easy to test
- No external dependencies

**Alternative**: CASL (considered but more complex than needed)

---

## API Design Decisions

### REST API Compatibility

**Decision**: Match Rails API exactly

**Rationale**:
- Frontend doesn't need changes
- Gradual migration possible
- No breaking changes

**Key Points**:
- Same endpoints
- Same request/response format
- Same error codes
- Same pagination

---

### Response Format

**Decision**: Keep snake_case (not camelCase)

**Rationale**:
- Matches Rails
- Frontend expects snake_case
- Consistency during migration

**Implementation**:
```typescript
// Serializer converts camelCase → snake_case
{
  id: user.id,
  email: user.email,
  created_at: user.createdAt,  // snake_case!
}
```

---

## Deployment Strategy

### Blue-Green Deployment

**Decision**: Run Rails (blue) and TypeScript (green) side-by-side

**Rationale**:
- Zero downtime
- Instant rollback
- Gradual traffic shift
- Safe migration

---

### Feature Flags

**Decision**: Use feature flags for traffic routing

**Rationale**:
- Gradual rollout (0% → 5% → 25% → 50% → 100%)
- Instant rollback
- A/B testing possible
- Per-feature rollout

---

## Monitoring Decisions

### Logging: Winston

**Decision**: Use Winston for logging

**Rationale**:
- Structured logging
- Multiple transports
- Log levels
- Good performance

---

### Metrics: Prometheus + Grafana

**Decision**: Use Prometheus for metrics, Grafana for visualization

**Rationale**:
- Industry standard
- Time-series data
- Great querying
- Beautiful dashboards

---

### Error Tracking: Sentry

**Decision**: Use Sentry for error tracking

**Rationale**:
- Automatic error capture
- Source maps support
- Release tracking
- Good integration

---

## Performance Optimizations

### Connection Pooling

**Decision**: Use connection pooling for database and Redis

**Rationale**:
- Reuse connections
- Better performance
- Handle high load

---

### Caching Strategy

**Decision**: Redis for caching

**Rationale**:
- Fast
- Already using for BullMQ
- Distributed caching
- TTL support

---

## Key Architectural Principles

1. **Consistency**: Follow NestJS and TypeORM best practices
2. **Testability**: All code must be testable
3. **Maintainability**: Clear, readable code over clever code
4. **Performance**: Optimize after working, not before
5. **Security**: Security-first approach (especially auth)

---

**Questions about architecture?** Ask the tech lead or discuss in team channel.
