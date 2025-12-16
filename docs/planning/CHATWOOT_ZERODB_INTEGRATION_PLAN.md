# ZeroDB Integration Mapping for Chatwoot

## 1. ARCHITECTURAL OVERVIEW

### Current Architecture
```
┌─────────────────────────────────────────────────────────┐
│                    Chatwoot Application                  │
│                  (Ruby on Rails)                          │
│                                                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   REST API   │  │  WebSocket   │  │  Admin UI    │   │
│  │  (200+ EPs)  │  │  Real-time   │  │              │   │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │
│         │                 │                  │            │
│         └─────────────────┼──────────────────┘            │
│                           │                               │
│         ┌─────────────────▼──────────────────┐            │
│         │   Business Logic Layer             │            │
│         │  (144 Services, Patterns)          │            │
│         └─────────────────┬──────────────────┘            │
│                           │                               │
│         ┌─────────────────▼──────────────────┐            │
│         │   Background Jobs (72)              │            │
│         │   (Sidekiq/ActiveJob)              │            │
│         └─────────────────┬──────────────────┘            │
│                           │                               │
└───────────────────────────┼────────────────────────────────┘
                            │
          ┌─────────────────┼─────────────────┬─────────────┐
          │                 │                 │             │
    ┌─────▼──────┐   ┌─────▼──────┐   ┌─────▼────┐  ┌─────▼──────┐
    │ PostgreSQL │   │    Redis   │   │Elasticsearch│  │    S3     │
    │ (Primary)  │   │ (Cache)    │   │(Search)   │  │(Files)    │
    └────────────┘   └────────────┘   └───────────┘  └───────────┘
```

### Proposed Enhancement with ZeroDB
```
┌──────────────────────────────────────────────────────────┐
│           Enhanced Chatwoot + ZeroDB                      │
│                                                            │
│  API Layer (unchanged)                                    │
│  │                                                        │
│  ├─ Services Layer (enhanced)                            │
│  │  ├─ Encryption services (ZeroDB integration)          │
│  │  ├─ Token vault service                               │
│  │  └─ Secure attribute service                          │
│  │                                                        │
│  └─ Data Layer (split)                                   │
│     │                                                    │
│     ├─ PostgreSQL (Plain)                               │
│     │  ├─ Conversations (metadata only)                 │
│     │  ├─ Messages (links to encrypted content)         │
│     │  └─ Public data                                   │
│     │                                                   │
│     ├─ ZeroDB (Encrypted)                               │
│     │  ├─ Contact sensitive info (email, phone)         │
│     │  ├─ Message content (encrypted search)            │
│     │  ├─ OAuth tokens & secrets                        │
│     │  ├─ Custom attributes                             │
│     │  └─ Audit trail                                   │
│     │                                                   │
│     ├─ Redis (Cache)                                    │
│     └─ S3 (Attachments)                                 │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## 2. SENSITIVE DATA CANDIDATES FOR ZERODB

### Priority 1: High-Sensitivity Data
```
Contact Table (PARTIAL MIGRATION)
├── Current: PostgreSQL (UNENCRYPTED)
├── Sensitive Fields:
│   ├── email           (Unique per account, searchable)
│   ├── phone_number    (Unique per account, searchable)
│   ├── identifier      (Custom ID, potentially PII)
│   └── custom_attributes (JSONB - often contains PII)
│
├── ZeroDB Migration:
│   ├── Store full contact in ZeroDB
│   ├── Keep minimal index in PostgreSQL:
│   │   ├── id
│   │   ├── account_id (for tenant isolation)
│   │   ├── contact_type
│   │   ├── last_activity_at
│   │   └── Hash of email (for lookups)
│   │
│   └── Query Pattern:
│       ├── Lookup by email hash → get ID
│       ├── Fetch from ZeroDB with ID + account_id
│       └── Decrypt & return
```

### Priority 2: Sensitive Business Data
```
Message Content (PARTIAL MIGRATION)
├── Current: PostgreSQL, Elasticsearch
├── To Encrypt:
│   ├── processed_message_content (full text)
│   ├── content_attributes.* (sensitive fields)
│   └── additional_attributes.* (conversation context)
│
├── ZeroDB Storage:
│   ├── Store encrypted message in ZeroDB
│   ├── Keep PostgreSQL index:
│   │   ├── id
│   │   ├── conversation_id
│   │   ├── created_at
│   │   ├── message_type (enum)
│   │   ├── status (enum)
│   │   └── Content fingerprint/hash
│   │
│   └── Search Strategy:
│       ├── Encrypted search on ZeroDB for content
│       ├── Or: Decrypt subset on demand
│       └── Use fingerprints for matching
```

### Priority 3: Integration Secrets
```
Integrations & Tokens
├── OAuth Access Tokens (Google, Microsoft, Slack)
├── API Keys (Linear, Notion, Shopify)
├── Webhook Secrets
├── Channel Credentials (Facebook, Instagram, Twitter)
└── SMS/Email Service Keys (Twilio, SendGrid)

Migration:
├── Create TokenVault in ZeroDB
├── Store as encrypted JSON:
│   {
│     "type": "oauth_token",
│     "provider": "google",
│     "account_id": "123",
│     "token": "encrypted(...)",
│     "refresh_token": "encrypted(...)",
│     "expires_at": "2025-01-01"
│   }
│
└── Service Layer:
    ├── TokenVaultService.store(account_id, type, token)
    ├── TokenVaultService.retrieve(account_id, type)
    └── Auto-refresh handling with rotation
```

### Priority 4: Custom Attributes & Settings
```
Custom Attributes (JSONB)
├── Current Location: PostgreSQL
├── Sensitive Examples:
│   ├── contacts.custom_attributes.company_vat_id
│   ├── contacts.custom_attributes.tax_id
│   ├── conversation.custom_attributes.* (user data)
│   └── account.settings.* (config with credentials)
│
├── ZeroDB Strategy:
│   ├── Store entire custom_attributes in ZeroDB
│   ├── Index frequently searched fields
│   ├── Keep non-sensitive attributes in PostgreSQL for speed
│   │
│   └── Query Pattern:
│       ├── SELECT id, name FROM contacts WHERE account_id = 123
│       ├── For each contact, fetch custom_attributes from ZeroDB
│       └── Lazy-load pattern for performance
```

---

## 3. DATA FLOW EXAMPLES

### Example 1: Secure Contact Lookup
```
Current Flow (PostgreSQL):
─────────────────────────
Client → API → ContactsController
  → ContactFinder
    → Contact.find_by(email: 'user@example.com', account_id: current_account.id)
      → PostgreSQL (returns unencrypted email)
        → Presenter
          → JSON response (email in clear text)

Enhanced Flow (PostgreSQL + ZeroDB):
────────────────────────────────────
Client → API → ContactsController
  → ContactFinder
    → Contact.find_by(email_hash: hash('user@example.com'), account_id: current_account.id)
      → PostgreSQL (returns contact ID from hash index)
        → EncryptedContactService.load(contact_id, account_id)
          → ZeroDB (decrypt with account encryption key)
            → Return decrypted contact object
              → Presenter
                → JSON response
```

### Example 2: Encrypted Message Search
```
Current Flow:
─────────────
Client → ConversationsController#search
  → Elasticsearch (plaintext search)
    → Returns message IDs
      → Message.where(id: [...])
        → PostgreSQL (returns plaintext content)

Enhanced Flow:
──────────────
Client → ConversationsController#search
  → EncryptedSearchService.search(query, account_id)
    → ZeroDB encrypted search
      ├─ If query in encrypted index → return message IDs
      └─ Else: Decrypt subset, search client-side
    → Message.where(id: [...])
      → PostgreSQL (metadata only)
        → MessageContentService.load(message_ids, account_id)
          → ZeroDB (decrypt with account key)
            → Presenter → JSON response
```

### Example 3: Token Refresh Flow
```
Current Flow:
─────────────
Integration calls → TokenService
  → User.find(id).tokens
    → Returns plaintext/partially encrypted token from DB
      → Check expiration
      → Call Google API to refresh
      → Update User.tokens (store updated token)
      → Continue integration

Enhanced Flow:
──────────────
Integration calls → TokenVaultService.get(account_id, 'google_oauth')
  → ZeroDB lookup (account_id + type index)
    → Decrypt token with account key
      → Check expiration
      ├─ Valid: Return token
      └─ Expired: 
          ├─ Call Google API refresh with decrypted refresh_token
          ├─ Encrypt new token
          ├─ Store in ZeroDB with rotation
          └─ Return new token
```

---

## 4. IMPLEMENTATION STRATEGY

### Phase 1: Foundation (Month 1)
```
1. Encrypt Contact Data
   ├─ Create ZeroDB schema for Contact
   ├─ Build EncryptedContactService
   │  ├─ load(contact_id, account_id)
   │  ├─ create(contact_data, account_id)
   │  ├─ update(contact_id, changes, account_id)
   │  └─ delete(contact_id, account_id)
   │
   ├─ Create encrypted index on:
   │  ├─ account_id
   │  ├─ email (with searchable encryption)
   │  └─ phone_number (with searchable encryption)
   │
   ├─ Migrate ContactsController:
   │  ├─ Override find method
   │  ├─ Lazy-load from ZeroDB
   │  └─ Cache in Redis (encrypted)
   │
   └─ Testing:
      ├─ Unit tests for EncryptedContactService
      ├─ Integration tests with ZeroDB
      └─ Performance tests vs PostgreSQL
```

### Phase 2: Message Encryption (Month 2)
```
1. Encrypt Message Content
   ├─ Create ZeroDB schema for Message content
   ├─ Build EncryptedMessageService
   │  ├─ store_content(message_id, content, account_id)
   │  ├─ retrieve_content(message_id, account_id)
   │  └─ search_content(query, account_id)
   │
   ├─ Update SendReplyJob:
   │  ├─ Store outgoing message content in ZeroDB
   │  ├─ Update PostgreSQL with link/status
   │  └─ Index in Elasticsearch (if enabled)
   │
   ├─ Update MessageBuilder:
   │  ├─ Intercept message creation
   │  ├─ Store in ZeroDB instead of PostgreSQL.content
   │  └─ Keep only metadata in PostgreSQL
   │
   └─ Update ConversationsController#messages:
      ├─ Fetch message metadata from PostgreSQL
      ├─ Batch load content from ZeroDB
      └─ Assemble response
```

### Phase 3: Token Vault (Month 2-3)
```
1. Centralized Encrypted Token Storage
   ├─ Create TokenVault in ZeroDB
   ├─ Build TokenVaultService
   │  ├─ store(account_id, token_type, token_data, expires_at)
   │  ├─ retrieve(account_id, token_type)
   │  ├─ refresh(account_id, token_type, refresh_callback)
   │  └─ revoke(account_id, token_type)
   │
   ├─ Migrate token storage:
   │  ├─ From: User.tokens (JSONB)
   │  ├─ From: Integrations::Hook.access_token
   │  ├─ From: Individual channel credentials
   │  ├─ To: TokenVault in ZeroDB
   │  │
   │  └─ Update services:
   │     ├─ Google::RefreshOauthTokenService
   │     ├─ Microsoft::RefreshOauthTokenService
   │     ├─ SlackIntegrationService
   │     └─ AllChannelServices
   │
   └─ Testing:
      ├─ Token rotation tests
      ├─ Expiration handling
      └─ Multi-account isolation
```

### Phase 4: Custom Attributes & Audit Trail (Month 3-4)
```
1. Encrypted Custom Attributes
   ├─ Build EncryptedAttributeService
   ├─ Migrate custom_attributes JSONB to ZeroDB
   └─ Keep searchable fields in PostgreSQL

2. Encrypted Audit Trail
   ├─ Create AuditLog schema in ZeroDB
   ├─ Intercept all model changes
   ├─ Store encrypted audit entries
   └─ Provide audit report generation
```

---

## 5. SERVICES TO CREATE/MODIFY

### New Services

```ruby
# app/services/zerodb/encrypted_contact_service.rb
class ZeroDB::EncryptedContactService
  def load(contact_id, account_id)
    # Query ZeroDB with account_id + contact_id
    # Decrypt using account encryption key
    # Return contact object
  end
  
  def create(contact_data, account_id)
    # Validate contact_data
    # Encrypt sensitive fields
    # Store in ZeroDB
    # Return contact with ID
  end
  
  def search(query, account_id, field)
    # Perform encrypted search
    # Return matching IDs
  end
end

# app/services/zerodb/token_vault_service.rb
class ZeroDB::TokenVaultService
  def store(account_id, token_type, token_data, expires_at)
    # Encrypt token_data
    # Store in ZeroDB with index on (account_id, token_type)
    # Track expiration for rotation
  end
  
  def retrieve(account_id, token_type)
    # Query ZeroDB
    # Return decrypted token
    # Check expiration
  end
  
  def refresh(account_id, token_type, refresh_callback)
    # Get current token
    # If expired, call refresh_callback
    # Store new token
    # Handle rotation
  end
end

# app/services/zerodb/encrypted_message_service.rb
class ZeroDB::EncryptedMessageService
  def store_content(message_id, content, account_id)
    # Encrypt message content
    # Store in ZeroDB
    # Update PostgreSQL message with reference
  end
  
  def retrieve_content(message_id, account_id)
    # Load from ZeroDB
    # Decrypt
    # Return content
  end
  
  def search(query, account_id)
    # Search encrypted messages
    # Return message IDs
  end
end

# app/services/zerodb/encrypted_attribute_service.rb
class ZeroDB::EncryptedAttributeService
  def load(entity_type, entity_id, account_id)
    # Load custom_attributes from ZeroDB
    # Decrypt
  end
  
  def update(entity_type, entity_id, changes, account_id)
    # Fetch current attributes
    # Apply changes
    # Encrypt and store
  end
end

# app/services/zerodb/audit_log_service.rb
class ZeroDB::AuditLogService
  def log_change(entity_type, entity_id, changes, account_id, user_id)
    # Create encrypted audit entry
    # Store in ZeroDB
    # Include timestamp, user, change details
  end
  
  def generate_report(account_id, entity_type, date_range)
    # Query encrypted audit logs
    # Generate report
    # Return decrypted results
  end
end
```

### Modified Services

```ruby
# app/services/contacts/filter_service.rb
# MODIFY: Use EncryptedContactService for sensitive field searches

# app/services/google/refresh_oauth_token_service.rb
# MODIFY: Use TokenVaultService instead of User.tokens

# app/services/messages/send_email_notification_service.rb
# MODIFY: Load encrypted message content from ZeroDB

# app/controllers/api/v1/accounts/contacts_controller.rb
# MODIFY: Use EncryptedContactService for loads

# app/controllers/api/v1/accounts/conversations/messages_controller.rb
# MODIFY: Lazy-load encrypted message content
```

---

## 6. DATABASE SCHEMA (PostgreSQL)

### Changes to Existing Tables

```sql
-- Minimal contact metadata in PostgreSQL
ALTER TABLE contacts ADD COLUMN IF NOT EXISTS
  email_hash VARCHAR(64) UNIQUE SCOPE (account_id),
  phone_hash VARCHAR(64) UNIQUE SCOPE (account_id),
  zerodb_id UUID REFERENCES zerodb_contacts(id),
  -- Hide content from direct access
  email VARCHAR(254) DEFAULT NULL,  -- Will be NULL, use email_hash
  phone_number VARCHAR(20) DEFAULT NULL,  -- Will be NULL, use phone_hash
  custom_attributes JSONB DEFAULT NULL;   -- Will be NULL, use ZeroDB

-- Messages: Keep metadata, encrypt content
ALTER TABLE messages ADD COLUMN IF NOT EXISTS
  content_encrypted BOOLEAN DEFAULT FALSE,
  zerodb_content_id UUID REFERENCES zerodb_message_contents(id),
  content TEXT DEFAULT NULL;  -- Will be NULL, use zerodb_content_id

-- Token vault reference
CREATE TABLE token_vaults (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id INTEGER NOT NULL REFERENCES accounts(id),
  token_type VARCHAR(50) NOT NULL,  -- 'oauth_google', 'oauth_slack', etc.
  zerodb_id UUID NOT NULL,
  expires_at TIMESTAMP,
  last_rotated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(account_id, token_type),
  INDEX(account_id, token_type)
);

-- Audit log reference
CREATE TABLE audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id INTEGER NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id INTEGER,
  zerodb_id UUID NOT NULL,
  user_id INTEGER,
  action VARCHAR(20),  -- 'create', 'update', 'delete'
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX(account_id, created_at),
  INDEX(entity_type, entity_id)
);
```

---

## 7. PERFORMANCE CONSIDERATIONS

### Latency Impacts
```
PostgreSQL lookup: ~1-5ms
ZeroDB lookup: ~5-20ms (depends on network, key size)
Decryption: ~2-10ms (AES-256, depends on data size)
Total: ~7-35ms (acceptable for most operations)

Optimization strategies:
├─ Cache decrypted objects in Redis (with TTL)
├─ Batch load operations when possible
├─ Use connection pooling
├─ Implement lazy-loading in views
└─ Async load non-critical data
```

### Caching Strategy
```
┌─────────────────────────────────────────┐
│         Application Cache (Redis)        │
├─────────────────────────────────────────┤
│ Key: "contact:{account_id}:{contact_id}"│
│ Value: Encrypted contact JSON           │
│ TTL: 5-30 minutes                       │
│                                         │
│ Invalidation on:                        │
│ ├─ contact.update                      │
│ ├─ custom_attributes change            │
│ └─ explicit cache clear                │
│                                         │
│ Fallback: Fetch from ZeroDB            │
└─────────────────────────────────────────┘
```

---

## 8. SECURITY ARCHITECTURE

### Encryption Keys
```
Master Key (AWS KMS / HashiCorp Vault)
  │
  ├─ Account Encryption Key (per account)
  │  ├─ Encrypts contacts
  │  ├─ Encrypts messages
  │  ├─ Encrypts custom attributes
  │  └─ Encrypts tokens
  │
  └─ Rotation Policy
     ├─ Key rotation every 90 days
     ├─ Old keys retained for decryption
     └─ Automated reencryption
```

### Searchable Encryption
```
For email field:
├─ Deterministic encryption for exact match
│  └─ Email -> AES-256-SIV -> Same ciphertext
│  └─ Allows index-based lookups
│
└─ Order-preserving encryption for sorting
   └─ Support ORDER BY in ZeroDB
```

### Multi-Tenant Isolation
```
Account ID included in encryption:
├─ Encrypt(account_id || data, account_key)
├─ Prevents decryption by other accounts
├─ Prevents cross-account data access
└─ Even if keys leaked, data tied to account
```

---

## 9. ROLLOUT PLAN

### Week 1-2: Setup & Testing
- [ ] Set up ZeroDB cluster
- [ ] Create test account
- [ ] Implement EncryptedContactService
- [ ] Write integration tests
- [ ] Performance benchmarks

### Week 3-4: Migration
- [ ] Deploy EncryptedContactService (feature flag off)
- [ ] Dual-write strategy (write to both PostgreSQL + ZeroDB)
- [ ] Verify data consistency
- [ ] Enable feature flag for 10% of accounts

### Week 5-6: Validation & Expansion
- [ ] Monitor error rates, latency
- [ ] Expand to 50% of accounts
- [ ] Migrate message content
- [ ] Implement message encryption

### Week 7-8: Token Vault & Full Deployment
- [ ] Deploy token vault
- [ ] Migrate all OAuth tokens
- [ ] Roll out to 100% of accounts
- [ ] Disable fallback to PostgreSQL
- [ ] Archive plaintext data

---

## 10. ROLLBACK PLAN

If issues arise:
```
├─ All reads still work (dual storage during transition)
├─ Toggle feature flags to fall back to PostgreSQL
├─ Maintain dual-write until stability confirmed
├─ Keep old data available for 30 days
└─ Automated testing to catch issues early
```

