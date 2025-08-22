# Chatwoot Caching and High-Volume Message Handling Analysis

## Overview
This report analyzes the caching mechanisms, database optimizations, and high-volume message handling strategies implemented in the Chatwoot CRM chat application.

## Research Progress
- [x] Initial repository structure analysis
- [x] Started database and caching configuration review
- [ ] Redis usage patterns analysis
- [ ] Message handling pipeline investigation
- [ ] Background job processing examination
- [ ] WebSocket/real-time messaging architecture
- [ ] Database optimization techniques
- [ ] Pagination and data loading strategies

---

## 1. Database and Caching Configuration

### Rails Configuration
**File:** `config/application.rb`
- Uses Rails 7.0 with standard eager loading
- Redis SSL verification mode configured for Heroku compatibility
- Custom configuration loaded via `config_for(:app)`

**File:** `config/environments/production.rb`
- `config.cache_classes = true` - Classes cached in production
- `config.action_controller.perform_caching = true` - Controller-level caching enabled
- Static files cached with 1-year max-age: `'Cache-Control' => "public, max-age=#{1.year.to_i}"`
- Uses Sidekiq as the Active Job queue adapter for background processing
- No specific cache store configured (defaults to Rails memory cache)

### Initial Cache-Related Files Discovered
From grep analysis, found 59 files with cache-related code and 65 files with Redis usage:

**Key Cache Files:**
- `app/models/concerns/cache_keys.rb` - Cache key generation
- `app/models/concerns/account_cache_revalidator.rb` - Account cache invalidation
- `app/helpers/cache_keys_helper.rb` - Cache key utilities
- `config/initializers/01_redis.rb` - Redis initialization
- `lib/redis/` directory - Redis utilities and configuration

**Database Cache Features:**
- `db/migrate/20231211010807_add_cached_labels_list.rb` - Cached labels implementation
- `app/jobs/migration/conversation_cache_label_job.rb` - Label caching jobs

---

## 2. Redis Infrastructure

### Redis Configuration (`lib/redis/config.rb`)
- **Base Configuration:**
  - Default URL: `redis://127.0.0.1:6379`
  - Configurable via `REDIS_URL` environment variable
  - Connection timeout: 1 second
  - Reconnect attempts: 2
  - SSL support with custom verification mode

- **Redis Sentinel Support:**
  - High availability configuration via `REDIS_SENTINELS` env var
  - Format: `host1:port1, host2:port2`
  - Master name configurable via `REDIS_SENTINEL_MASTER_NAME`
  - Default sentinel port: 26379

### Redis Connection Pools (`config/initializers/01_redis.rb`)
Two dedicated Redis connection pools with namespacing:

1. **Alfred Pool** (`$alfred`)
   - Size: 5 connections, 1-second timeout
   - Namespace: `alfred`
   - Used for: Round Robin, Conversation Emails, Online Presence
   - Uses MockRedis in test environment

2. **Velma Pool** (`$velma`)
   - Size: 5 connections, 1-second timeout  
   - Namespace: `velma`
   - Used for: Rack Attack (rate limiting)
   - Uses MockRedis in test environment

### Redis Key Structure (`lib/redis/redis_keys.rb`)
Well-organized key naming conventions:

**Inbox Management:**
- `ROUND_ROBIN_AGENTS:%<inbox_id>d` - Agent assignment queue

**Conversation Management:**
- `CONVERSATION::%<conversation_id>d` - Email reply detection
- `CONVERSATION::%<id>d::MUTED` - Mute status
- `CONVERSATION::%<id>d::DRAFT_MESSAGE` - Draft messages

**User Management:**
- `USER_SSO_AUTH_TOKEN::%<user_id>d::%<token>s` - SSO tokens

**Online Status Tracking:**
- `ONLINE_STATUS::%<account_id>d` - User online status hash
- `ONLINE_PRESENCE::%<account_id>d::CONTACTS` - Contact presence (sorted set)
- `ONLINE_PRESENCE::%<account_id>d::USERS` - User presence (sorted set)

**Message Processing Locks:**
- `FB_MESSAGE_CREATE_LOCK::%<sender_id>s::%<recipient_id>s`
- `IG_MESSAGE_CREATE_LOCK::%<sender_id>s::%<ig_account_id>s`
- `SLACK_MESSAGE_LOCK::%<conversation_id>s::%<reference_id>s`
- `EMAIL_CHANNEL_LOCK::%<inbox_id>s`
- `CRM_PROCESS_MUTEX::%<hook_id>s`

### Cache Key Management (`app/models/concerns/cache_keys.rb`)
- **Cache Expiry:** 72 hours for all cache keys
- **Cacheable Models:** Label, Inbox, Team
- **Cache Invalidation:** Event-driven via dispatcher
- **Account-level caching:** Each account has isolated cache keys
- **Automatic cache key updates:** When models change

---

## 3. Message Handling and Processing Pipeline

### Message Model Optimizations (`app/models/message.rb`)
**Database Indexes:** Extensive indexing strategy for high-volume queries:
- `idx_messages_account_content_created` - Account, content type, creation time
- `index_messages_on_account_created_type` - Account, creation, message type  
- `index_messages_on_conversation_account_type_created` - Conversation queries
- `index_messages_on_content` - GIN index for full-text search
- `index_messages_on_additional_attributes_campaign_id` - Campaign tracking

**Performance Features:**
- **Message Flooding Prevention:** Max 1 message per minute per conversation via `Limits.conversation_message_per_minute_limit`
- **Content Truncation:** 150,000 character limit for content and processed content
- **Attachment Limit:** 15 attachments per message
- **Default Ordering:** `created_at: :asc` for chronological message display

### High-Volume Message Processing

**Incoming Message Services:**
- `Whatsapp::IncomingMessageBaseService` - WhatsApp message processing
- Multiple channel-specific services: Telegram, Twilio, SMS, Line, Instagram
- **Duplicate Prevention:** Redis-based source ID caching to prevent duplicate messages
- **Mutex Locks:** Channel-specific locks to prevent concurrent processing:
  - `FB_MESSAGE_CREATE_LOCK`
  - `IG_MESSAGE_CREATE_LOCK` 
  - `SLACK_MESSAGE_LOCK`
  - `EMAIL_CHANNEL_LOCK`

**Message Processing Flow:**
1. **Validation:** Check for unprocessable message types and duplicates
2. **Redis Lock:** Cache message source ID to prevent concurrent processing
3. **Contact Resolution:** Create/find contact using `ContactInboxWithContactBuilder`
4. **Conversation Management:** Single conversation lock or create new for resolved conversations
5. **Message Creation:** Build message with attachments, location data, contacts
6. **Cleanup:** Clear Redis locks after processing

### Email Reply Optimization (`app/models/message.rb:396-412`)
**Batched Email Delivery:** Sophisticated email batching to reduce notification volume:
- **Redis Key Check:** `Redis::Alfred.get(conversation_mail_key)` prevents duplicate emails
- **2-minute Batching:** `ConversationReplyEmailWorker.perform_in(2.minutes)` groups messages
- **Immediate Email Channel:** Direct emails for Email inbox type with 1-second delay

---

## 4. Background Job Processing and Queue Management

### Sidekiq Configuration (`config/initializers/sidekiq.rb`)
- **Redis Backend:** Uses shared Redis configuration via `Redis::Config.app`
- **Production Logging:** JSON formatted logs with configurable log level
- **Cron Jobs:** Automated scheduling via `sidekiq-cron` with YAML configuration
- **Job Logging:** Disabled default logging in production for performance

### Job Architecture
**Core Jobs Identified:** 26 different job types handling various aspects:

**Message Processing Jobs:**
- `SendReplyJob` - Async message delivery (2-second delay for attachments)
- `ConversationReplyEmailWorker` - Batched email notifications
- `EmailReplyWorker` - Immediate email processing
- `ActionCableBroadcastJob` - Real-time WebSocket updates

**Integration Jobs:**
- `Webhooks::*EventsJob` - Platform-specific webhook processing (Facebook, Instagram, WhatsApp, etc.)
- `HookJob` - Generic webhook delivery
- `SlackUnfurlJob` - Slack link previews

**Maintenance Jobs:**
- `Internal::RemoveStaleRedisKeysJob` - Redis cleanup
- `Internal::ProcessStaleContactsJob` - Contact cleanup
- `Account::ConversationsResolutionSchedulerJob` - Auto-resolution

**High Performance Features:**
- **Async Job Dispatch:** 343 `perform_later/perform_in/perform_async` calls across 182 files
- **Delayed Processing:** Strategic delays (1-2 seconds) for attachment uploads
- **Background Processing:** All heavy operations moved to background jobs

---

## 5. Anti-Spam and Rate Limiting

### Message Flooding Protection
- **Rate Limiting:** 1 message per minute per conversation maximum
- **Validation:** Built into Message model with detailed error logging
- **Account/Conversation Level:** Prevents automation loops and spam

### Redis-Based Duplicate Prevention
- **Source ID Caching:** `MESSAGE_SOURCE_KEY::%<id>s` prevents duplicate webhook processing
- **Mutex Locks:** Prevent concurrent message creation from same sender
- **TTL-Based:** Automatic cleanup of temporary prevention keys

---

## 6. Database Optimization and Indexing Strategy

### PostgreSQL Extensions
**Advanced Database Features Enabled:**
- `pg_stat_statements` - Query performance monitoring
- `pg_trgm` - Trigram matching for fuzzy text search
- `pgcrypto` - Cryptographic functions
- `vector` - Vector similarity search for AI/ML features

### Key Database Indexes
**High-Performance Indexes for Chat CRM:**
- **Messages Table:**
  - `idx_messages_account_content_created` - Account + content type + timestamp
  - `index_messages_on_content` - **GIN index** for full-text search
  - `index_messages_on_conversation_account_type_created` - Conversation queries
  - `index_messages_on_additional_attributes_campaign_id` - **GIN index** for JSON campaign tracking

- **Specialized Indexes:**
  - `index_article_embeddings_on_embedding` - **IVFFlat index** for vector similarity search  
  - `index_active_storage_attachments_uniqueness` - Composite unique constraint
  - `uniq_user_id_per_account_id` - Account user relationship uniqueness

### Query Optimization Features
- **Unique Constraints:** Prevent duplicate records across critical relationships
- **Composite Indexes:** Multi-column indexes for complex filtering
- **JSON Indexing:** GIN indexes on JSONB columns for fast JSON queries
- **Vector Search:** IVFFlat indexing for AI-powered semantic search

---

## 7. WebSocket/Real-Time Messaging Architecture

### ActionCable Configuration (`config/initializers/actioncable.rb`)
**Redis-Backed WebSocket Infrastructure:**
- **Redis Adapter:** Uses shared Redis configuration via `ActionCable::SubscriptionAdapter::Redis`
- **GCP Memorystore Support:** Configurable client command disabling for cloud compatibility
- **Channel Isolation:** Account-specific channel broadcasting

### Real-Time Channel Architecture (`app/channels/room_channel.rb`)
**High-Performance WebSocket Channels:**
- **Dual Streaming:** User and account-level streams for granular updates
- **Presence Tracking:** Real-time online status via `OnlineStatusTracker`
- **Authentication:** Token-based authentication for users and contacts
- **Broadcast Optimization:** Targeted broadcasts to specific account/user combinations

### Online Status Management (`lib/online_status_tracker.rb`)
**Redis-Based Presence System:**
- **Sorted Sets:** Timestamp-scored presence tracking with automatic cleanup
- **Presence Duration:** Configurable online duration (default 20 seconds)
- **Automatic Cleanup:** `zremrangebyscore` removes stale presence records
- **Status Tracking:** Hash-based online/busy/offline status management

---

## 8. Pagination and Data Loading Strategies

### Pagination Implementation (`app/controllers/api/v1/accounts/contacts_controller.rb`)
**Performance-Optimized Pagination:**
- **Fixed Page Size:** `RESULTS_PER_PAGE = 15` for consistent performance
- **Count Tracking:** Separate count queries for total records
- **Smart Loading:** `set_include_contact_inboxes` for conditional relationship loading
- **Sort Optimization:** Multiple sort options with database-level sorting

### Advanced Filtering and Search
**High-Volume Search Capabilities:**
- **ILIKE Search:** Multi-field text search across name, email, phone, company
- **JSON Attribute Search:** Search within `additional_attributes` JSON column  
- **Custom Filter Service:** `Contacts::FilterService` for complex filtering
- **Online Contact Filtering:** Redis-based active contact filtering

---

## Summary: High-Volume Message Handling Strategies

### Database-Level Optimizations
1. **Extensive Indexing:** 20+ strategic indexes including GIN and composite indexes
2. **PostgreSQL Extensions:** Advanced features like trigram search and vector similarity
3. **Query Optimization:** Specialized indexes for common query patterns
4. **JSON Performance:** GIN indexes on JSONB columns for fast JSON operations

### Redis-Based Performance Features
1. **Dual Connection Pools:** Separated Alfred/Velma pools for different use cases
2. **Comprehensive Key Management:** Well-organized key naming with TTL cleanup
3. **Message Deduplication:** Source ID caching prevents duplicate processing
4. **Presence Tracking:** Real-time online status with automatic cleanup

### Message Processing Pipeline
1. **Async Processing:** 343 background job calls across 182 files
2. **Mutex Locks:** Channel-specific locks prevent concurrent processing conflicts
3. **Email Batching:** 2-minute batching reduces notification volume
4. **Flooding Prevention:** Rate limiting at 1 message/minute per conversation

### Real-Time Infrastructure
1. **ActionCable + Redis:** WebSocket infrastructure with Redis pub/sub
2. **Account Isolation:** Dedicated channels per account for security/performance
3. **Presence Management:** Redis sorted sets for efficient online status tracking
4. **Broadcast Optimization:** Targeted messaging to specific user/account combinations
