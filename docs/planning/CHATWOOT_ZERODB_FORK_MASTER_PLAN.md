# Chatwoot-ZeroDB Fork: Master Implementation Plan

**Version:** 1.0
**Date:** December 5, 2025
**Status:** Planning Phase

---

## 🎯 Executive Summary

### Objective
Create a **lightweight fork of Chatwoot** (open-source customer support platform) that replaces its PostgreSQL database with **ZeroDB**, positioning it as a **showcase application** and **signup driver** for ZeroDB services.

### Strategic Goals
1. **Replace PostgreSQL with ZeroDB** - Complete database migration from Postgres to ZeroDB's PostgreSQL + NoSQL + Vector capabilities
2. **Enhance with ZeroDB Features** - Add AI-powered features using ZeroDB's vector search, embeddings, and memory APIs
3. **Generate ZeroDB Signups** - Use the enhanced Chatwoot as a compelling demo to drive ZeroDB adoption
4. **Showcase ZeroDB Capabilities** - Demonstrate real-world usage of all 15 ZeroDB tools in production

### Success Metrics
- ✅ 100% feature parity with original Chatwoot
- ✅ 3 new AI-powered features using ZeroDB
- ✅ 50% faster semantic search vs. traditional full-text
- ✅ 10+ ZeroDB signups per month from Chatwoot users
- ✅ Public GitHub repo with clear ZeroDB integration docs

---

## 📊 Current State Analysis

### Chatwoot Architecture
- **Framework:** Ruby on Rails 7.1
- **Database:** PostgreSQL 15+ with pgvector extension
- **ORM:** ActiveRecord with 84 tables
- **Cache/Jobs:** Redis + Sidekiq
- **Search:** Searchkick (Elasticsearch/OpenSearch)
- **Features:**
  - Multi-tenant (account_id isolation)
  - Real-time messaging via ActionCable
  - 11 communication channels (Email, Facebook, WhatsApp, etc.)
  - AI assistant ("Captain") with OpenAI integration
  - Help center with article search
  - Team inbox with automation rules

### Database Breakdown
| Category | Tables | Key Tables |
|----------|--------|-----------|
| Core | 12 | accounts, users, inboxes, conversations, messages |
| Contacts | 8 | contacts, contact_inboxes, custom_attributes |
| Automation | 6 | automation_rules, macros, canned_responses |
| Reporting | 5 | reporting_events, events, audits |
| Integrations | 7 | integrations, webhooks, channel_*  |
| AI/Search | 3 | articles, portals (pgvector) |
| **Total** | **84** | 1,287 lines in schema.rb |

### ZeroDB Capabilities Available
1. **PostgreSQL Foundation** - Project-isolated Postgres with pgvector
2. **NoSQL Tables** - MongoDB-style document storage for flexible schemas
3. **Vector Operations** - Embeddings (FREE 384-dim), semantic search, RAG
4. **Memory Management** - Agent memory storage and retrieval
5. **RLHF Feedback** - User interaction tracking for model improvement
6. **Event Streaming** - Real-time event publishing
7. **File Storage** - S3-compatible object storage
8. **SQL Execution** - Direct SQL with security validation
9. **Agent Activity Logs** - Monitor agent performance
10. **Embeddings API** - Free BAAI/bge-small-en-v1.5 (384-dim)
11. **Dedicated PostgreSQL** - Optional dedicated instances
12. **Quantum Enhancement** - Vector compression (Scale tier)
13. **Hybrid Search** - Combine semantic + keyword + vector
14. **Multi-Metric Similarity** - 8 similarity algorithms
15. **Advanced Analytics** - ML-powered insights

---

## 🏗️ Migration Strategy: Postgres → ZeroDB

### Approach: **Hybrid Model** (Best of Both Worlds)

Instead of a complete replacement, use ZeroDB's **dual-mode architecture**:
- **Dedicated PostgreSQL Instance** for core relational data (accounts, users, conversations)
- **ZeroDB NoSQL + Vector** for AI-enhanced features (semantic search, memory, RLHF)

### Why Hybrid?
✅ **100% compatibility** - All existing Chatwoot features work unchanged
✅ **Easy migration** - Point Rails to ZeroDB dedicated PostgreSQL
✅ **Enhanced features** - Add ZeroDB vector/memory APIs on top
✅ **Cost-effective** - Free embeddings + serverless NoSQL
✅ **Gradual rollout** - Migrate in phases without breaking changes

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Chatwoot-ZeroDB Fork                      │
│                   (Ruby on Rails 7.1)                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
         ┌─────────────┴─────────────┐
         │                           │
         ▼                           ▼
┌────────────────────┐     ┌─────────────────────┐
│  ZeroDB Dedicated  │     │  ZeroDB Serverless  │
│   PostgreSQL       │     │    NoSQL + Vector   │
│   (Core Data)      │     │  (AI Features)      │
├────────────────────┤     ├─────────────────────┤
│ • accounts         │     │ • Semantic Search   │
│ • users            │     │ • Agent Memory      │
│ • conversations    │     │ • RLHF Feedback     │
│ • messages         │     │ • Smart Suggestions │
│ • contacts         │     │ • Content Vectors   │
│ • inboxes          │     │ • Event Streaming   │
│ • teams            │     │ • File Storage      │
│                    │     │                     │
│ Rails ActiveRecord │     │ ZeroDB Ruby SDK     │
│ (No changes)       │     │ (New integration)   │
└────────────────────┘     └─────────────────────┘
         │                           │
         └───────────┬───────────────┘
                     │
                     ▼
           ┌──────────────────┐
           │  Redis/Sidekiq   │
           │  (Background)    │
           └──────────────────┘
```

---

## 🔄 Phase 1: Database Migration (Week 1-2)

### Step 1.1: Provision ZeroDB Dedicated PostgreSQL

**Goal:** Replace Chatwoot's Postgres with ZeroDB Dedicated PostgreSQL
**Timeline:** Day 1-2

#### Action Items:
```bash
# 1. Create ZeroDB account (if not exists)
curl -X POST https://api.ainative.studio/v1/public/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "chatwoot@ainative.studio",
    "password": "secure_password"
  }'

# 2. Create ZeroDB project
curl -X POST https://api.ainative.studio/v1/public/projects \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{
    "name": "Chatwoot Production",
    "description": "Chatwoot customer support platform",
    "tier": "pro",
    "database_enabled": true
  }'

# 3. Provision dedicated PostgreSQL instance
curl -X POST https://api.ainative.studio/v1/public/{project_id}/postgres/provision \
  -H "X-API-Key: YOUR_API_KEY" \
  -d '{
    "instance_size": "standard-4",
    "database_name": "chatwoot_production",
    "version": "15",
    "storage_gb": 100,
    "max_connections": 200,
    "backup_enabled": true,
    "backup_retention_days": 30
  }'

# 4. Get connection details
curl https://api.ainative.studio/v1/public/{project_id}/postgres/{instance_id}/connection \
  -H "X-API-Key: YOUR_API_KEY"
```

**Expected Response:**
```json
{
  "host": "postgres-550e8400.railway.app",
  "port": 5432,
  "database": "chatwoot_production",
  "username": "postgres_user_550e8400",
  "password": "GENERATED_PASSWORD",
  "connection_string": "postgresql://postgres_user_550e8400:PASS@postgres-550e8400.railway.app:5432/chatwoot_production",
  "ssl_required": true,
  "extensions": ["pgvector", "pg_stat_statements", "uuid-ossp"]
}
```

### Step 1.2: Update Chatwoot Database Configuration

**File:** `/Users/aideveloper/chatwoot-test/config/database.yml`

```yaml
# BEFORE (Original Chatwoot)
production:
  <<: *default
  database: "<%= ENV.fetch('POSTGRES_DATABASE', 'chatwoot_production') %>"
  username: "<%= ENV.fetch('POSTGRES_USERNAME', 'chatwoot_prod') %>"
  password: "<%= ENV.fetch('POSTGRES_PASSWORD', 'chatwoot_prod') %>"

# AFTER (ZeroDB Dedicated PostgreSQL)
production:
  <<: *default
  host: "<%= ENV.fetch('ZERODB_POSTGRES_HOST', 'postgres-550e8400.railway.app') %>"
  port: <%= ENV.fetch('ZERODB_POSTGRES_PORT', '5432') %>
  database: "<%= ENV.fetch('ZERODB_POSTGRES_DATABASE', 'chatwoot_production') %>"
  username: "<%= ENV.fetch('ZERODB_POSTGRES_USERNAME', 'postgres_user_550e8400') %>"
  password: "<%= ENV.fetch('ZERODB_POSTGRES_PASSWORD', '') %>"
  sslmode: require
```

**Environment Variables (.env):**
```bash
# ZeroDB Dedicated PostgreSQL
ZERODB_POSTGRES_HOST=postgres-550e8400.railway.app
ZERODB_POSTGRES_PORT=5432
ZERODB_POSTGRES_DATABASE=chatwoot_production
ZERODB_POSTGRES_USERNAME=postgres_user_550e8400
ZERODB_POSTGRES_PASSWORD=GENERATED_PASSWORD

# ZeroDB API (for NoSQL/Vector features)
ZERODB_API_KEY=YOUR_API_KEY
ZERODB_PROJECT_ID=550e8400-e29b-41d4-a716-446655440000
ZERODB_API_URL=https://api.ainative.studio/v1/public
```

### Step 1.3: Migrate Existing Data

**Timeline:** Day 3-5

```bash
# 1. Dump existing Chatwoot database
cd /Users/aideveloper/chatwoot-test
pg_dump -h localhost -U postgres -d chatwoot_dev > chatwoot_backup.sql

# 2. Restore to ZeroDB Dedicated PostgreSQL
psql -h postgres-550e8400.railway.app \
     -U postgres_user_550e8400 \
     -d chatwoot_production \
     -f chatwoot_backup.sql

# 3. Verify migration
psql -h postgres-550e8400.railway.app \
     -U postgres_user_550e8400 \
     -d chatwoot_production \
     -c "SELECT COUNT(*) FROM accounts;"
```

### Step 1.4: Test & Validate

**Checklist:**
- [ ] Run Chatwoot migrations: `bundle exec rails db:migrate`
- [ ] Seed test data: `bundle exec rails db:seed`
- [ ] Start Rails server: `bundle exec rails s`
- [ ] Test core features:
  - [ ] User login/logout
  - [ ] Create conversation
  - [ ] Send message
  - [ ] Search contacts
  - [ ] View reports
- [ ] Run RSpec tests: `bundle exec rspec`
- [ ] Check logs for errors: `tail -f log/production.log`

**Success Criteria:**
✅ All tests passing
✅ No database connection errors
✅ Existing data accessible
✅ All features working

---

## 🚀 Phase 2: ZeroDB Integration - AI Features (Week 3-6)

### Overview
Add 5 new AI-powered features using ZeroDB's NoSQL, Vector, and Memory APIs:

1. **Semantic Conversation Search** - Find conversations by meaning, not just keywords
2. **Smart Canned Response Suggestions** - AI-powered response recommendations
3. **Agent Memory & Context** - Remember customer preferences across conversations
4. **RLHF Feedback Loop** - Improve AI responses based on agent feedback
5. **Similar Ticket Detection** - Automatically find related conversations

### Feature 2.1: Semantic Conversation Search

**Problem:** Current search uses Elasticsearch/keyword matching - misses semantic relevance
**Solution:** ZeroDB vector search with free embeddings

#### Implementation

**New Service:** `app/services/zerodb/semantic_search_service.rb`

```ruby
# app/services/zerodb/semantic_search_service.rb
module Zerodb
  class SemanticSearchService
    include HTTParty
    base_uri ENV.fetch('ZERODB_API_URL', 'https://api.ainative.studio/v1/public')

    def initialize(account_id)
      @account_id = account_id
      @project_id = ENV['ZERODB_PROJECT_ID']
      @api_key = ENV['ZERODB_API_KEY']
    end

    # Index conversation for semantic search
    def index_conversation(conversation)
      # Generate embedding from conversation content
      embedding_response = generate_embedding(conversation_text(conversation))

      # Store in ZeroDB vector database
      HTTParty.post(
        "#{self.class.base_uri}/#{@project_id}/database/vectors/upsert",
        headers: {
          'X-API-Key' => @api_key,
          'Content-Type' => 'application/json'
        },
        body: {
          id: "conversation_#{conversation.id}",
          vector: embedding_response['embeddings'][0],
          metadata: {
            conversation_id: conversation.id,
            account_id: @account_id,
            inbox_id: conversation.inbox_id,
            status: conversation.status,
            created_at: conversation.created_at.iso8601,
            contact_name: conversation.contact.name,
            subject: conversation.additional_attributes['subject'],
            summary: conversation_summary(conversation)
          },
          namespace: "conversations_#{@account_id}"
        }.to_json
      )
    end

    # Search conversations semantically
    def search(query, limit: 10, filters: {})
      # Generate query embedding
      query_embedding = generate_embedding(query)['embeddings'][0]

      # Search ZeroDB
      response = HTTParty.post(
        "#{self.class.base_uri}/#{@project_id}/embeddings/search",
        headers: {
          'X-API-Key' => @api_key,
          'Content-Type' => 'application/json'
        },
        body: {
          query: query,
          top_k: limit,
          namespace: "conversations_#{@account_id}",
          filter: filters,
          similarity_threshold: 0.7,
          include_metadata: true
        }.to_json
      )

      # Map results to Conversation models
      results = JSON.parse(response.body)['results']
      conversation_ids = results.map { |r| r['metadata']['conversation_id'] }

      Conversation.where(id: conversation_ids, account_id: @account_id)
                 .order("ARRAY_POSITION(ARRAY[#{conversation_ids.join(',')}], id::integer)")
    end

    private

    def generate_embedding(text)
      response = HTTParty.post(
        "#{self.class.base_uri}/#{@project_id}/embeddings/generate",
        headers: {
          'X-API-Key' => @api_key,
          'Content-Type' => 'application/json'
        },
        body: {
          texts: [text],
          model: 'custom-1536'
        }.to_json
      )
      JSON.parse(response.body)
    end

    def conversation_text(conversation)
      messages = conversation.messages.last(10).map(&:content).join(' ')
      "Subject: #{conversation.additional_attributes['subject']}. Messages: #{messages}"
    end

    def conversation_summary(conversation)
      conversation.messages.last(5).map(&:content).join(' ').truncate(500)
    end
  end
end
```

**Background Job:** `app/jobs/zerodb/index_conversation_job.rb`

```ruby
# app/jobs/zerodb/index_conversation_job.rb
module Zerodb
  class IndexConversationJob < ApplicationJob
    queue_as :low

    def perform(conversation_id)
      conversation = Conversation.find_by(id: conversation_id)
      return unless conversation

      Zerodb::SemanticSearchService.new(conversation.account_id)
                                   .index_conversation(conversation)
    rescue => e
      Rails.logger.error("ZeroDB indexing failed for conversation #{conversation_id}: #{e.message}")
    end
  end
end
```

**Trigger Indexing on Message Creation:**

```ruby
# app/models/message.rb (add after_create callback)
class Message < ApplicationRecord
  # ... existing code ...

  after_create :index_conversation_async

  private

  def index_conversation_async
    Zerodb::IndexConversationJob.perform_later(conversation_id) if conversation.present?
  end
end
```

**API Controller:** `app/controllers/api/v1/accounts/conversations/semantic_search_controller.rb`

```ruby
# app/controllers/api/v1/accounts/conversations/semantic_search_controller.rb
class Api::V1::Accounts::Conversations::SemanticSearchController < Api::V1::Accounts::BaseController
  def create
    @conversations = Zerodb::SemanticSearchService.new(Current.account.id)
                                                   .search(
                                                     params[:query],
                                                     limit: params[:limit] || 20,
                                                     filters: search_filters
                                                   )

    render json: @conversations,
           meta: { total_count: @conversations.count },
           status: :ok
  end

  private

  def search_filters
    filters = {}
    filters[:status] = params[:status] if params[:status].present?
    filters[:inbox_id] = params[:inbox_id] if params[:inbox_id].present?
    filters
  end
end
```

**Add Route:**
```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    resources :accounts, only: [] do
      scope module: :accounts do
        resources :conversations do
          collection do
            post :semantic_search
          end
        end
      end
    end
  end
end
```

**Frontend Integration (Vue.js):**

```vue
<!-- app/javascript/dashboard/routes/dashboard/conversation/search/SemanticSearch.vue -->
<template>
  <div class="semantic-search">
    <div class="search-input">
      <input
        v-model="searchQuery"
        type="text"
        placeholder="Search conversations by meaning (e.g., 'customer wants refund')"
        @input="debounceSearch"
        class="form-input"
      />
      <span class="powered-by">Powered by ZeroDB AI</span>
    </div>

    <div v-if="loading" class="loading">
      <spinner />
      Searching...
    </div>

    <div v-if="results.length > 0" class="results">
      <h3>Found {{ results.length }} semantically similar conversations</h3>
      <conversation-card
        v-for="conversation in results"
        :key="conversation.id"
        :conversation="conversation"
      />
    </div>
  </div>
</template>

<script>
import { debounce } from 'lodash';
import ConversationCard from './ConversationCard.vue';

export default {
  components: { ConversationCard },
  data() {
    return {
      searchQuery: '',
      results: [],
      loading: false
    };
  },
  methods: {
    debounceSearch: debounce(function() {
      this.performSemanticSearch();
    }, 500),

    async performSemanticSearch() {
      if (this.searchQuery.length < 3) {
        this.results = [];
        return;
      }

      this.loading = true;
      try {
        const response = await this.$axios.post(
          `/api/v1/accounts/${this.accountId}/conversations/semantic_search`,
          {
            query: this.searchQuery,
            limit: 20
          }
        );
        this.results = response.data;
      } catch (error) {
        console.error('Semantic search failed:', error);
      } finally {
        this.loading = false;
      }
    }
  }
};
</script>
```

**Cost Analysis:**
- **Embeddings:** FREE (ZeroDB's BAAI/bge-small-en-v1.5)
- **Vector Storage:** ~0.001 credits per vector (10,000 conversations = $10/month)
- **Search Queries:** ~0.01 credits per search (1,000 searches/day = $10/month)
- **Total:** ~$20/month for 10k conversations + 1k searches/day

---

### Feature 2.2: Smart Canned Response Suggestions

**Problem:** Agents manually search for canned responses - slow and inconsistent
**Solution:** AI suggests relevant canned responses based on conversation context

#### Implementation

**Service:** `app/services/zerodb/canned_response_suggester.rb`

```ruby
module Zerodb
  class CannedResponseSuggester
    include HTTParty
    base_uri ENV.fetch('ZERODB_API_URL', 'https://api.ainative.studio/v1/public')

    def initialize(account_id)
      @account_id = account_id
      @project_id = ENV['ZERODB_PROJECT_ID']
      @api_key = ENV['ZERODB_API_KEY']
    end

    # Index all canned responses on account creation/update
    def index_all_responses
      CannedResponse.where(account_id: @account_id).find_each do |response|
        index_response(response)
      end
    end

    # Index single canned response
    def index_response(canned_response)
      # Use ZeroDB embed_and_store endpoint
      HTTParty.post(
        "#{self.class.base_uri}/#{@project_id}/embeddings/embed-and-store",
        headers: headers,
        body: {
          documents: [
            {
              id: "canned_response_#{canned_response.id}",
              text: "#{canned_response.short_code}: #{canned_response.content}",
              metadata: {
                response_id: canned_response.id,
                account_id: @account_id,
                short_code: canned_response.short_code,
                content: canned_response.content
              }
            }
          ],
          namespace: "canned_responses_#{@account_id}",
          upsert: true
        }.to_json
      )
    end

    # Suggest responses for a conversation
    def suggest(conversation, limit: 5)
      # Get last 3 customer messages as context
      context = conversation.messages
                           .where(message_type: :incoming)
                           .last(3)
                           .map(&:content)
                           .join(' ')

      # Search for similar canned responses
      response = HTTParty.post(
        "#{self.class.base_uri}/#{@project_id}/embeddings/search",
        headers: headers,
        body: {
          query: context,
          top_k: limit,
          namespace: "canned_responses_#{@account_id}",
          similarity_threshold: 0.6,
          include_metadata: true
        }.to_json
      )

      results = JSON.parse(response.body)['results']
      response_ids = results.map { |r| r['metadata']['response_id'] }

      CannedResponse.where(id: response_ids, account_id: @account_id)
                   .order("ARRAY_POSITION(ARRAY[#{response_ids.join(',')}], id::integer)")
    end

    private

    def headers
      {
        'X-API-Key' => @api_key,
        'Content-Type' => 'application/json'
      }
    end
  end
end
```

**API Endpoint:**
```ruby
# app/controllers/api/v1/accounts/conversations/canned_response_suggestions_controller.rb
class Api::V1::Accounts::Conversations::CannedResponseSuggestionsController < Api::V1::Accounts::BaseController
  def index
    conversation = Current.account.conversations.find(params[:conversation_id])

    @suggestions = Zerodb::CannedResponseSuggester.new(Current.account.id)
                                                   .suggest(conversation, limit: 5)

    render json: @suggestions, status: :ok
  end
end
```

**Frontend Widget:**
```vue
<!-- Smart suggestions sidebar in conversation view -->
<template>
  <div class="canned-response-suggestions">
    <h4>💡 AI-Suggested Responses</h4>
    <p class="subtitle">Based on conversation context</p>

    <div v-for="suggestion in suggestions" :key="suggestion.id" class="suggestion-card">
      <div class="suggestion-header">
        <span class="short-code">{{ suggestion.short_code }}</span>
        <button @click="useSuggestion(suggestion)" class="use-btn">Use</button>
      </div>
      <p class="suggestion-content">{{ suggestion.content }}</p>
    </div>
  </div>
</template>
```

---

### Feature 2.3: Agent Memory & Context

**Problem:** Agents forget customer preferences across conversations
**Solution:** ZeroDB Memory API to store and recall customer context

**Service:** `app/services/zerodb/agent_memory_service.rb`

```ruby
module Zerodb
  class AgentMemoryService
    include HTTParty
    base_uri ENV.fetch('ZERODB_API_URL', 'https://api.ainative.studio/v1/public')

    def initialize(account_id)
      @account_id = account_id
      @project_id = ENV['ZERODB_PROJECT_ID']
      @api_key = ENV['ZERODB_API_KEY']
    end

    # Store customer preference/note
    def store_memory(contact_id, content, importance: 'medium', tags: [])
      HTTParty.post(
        "#{self.class.base_uri}/#{@project_id}/database/memory",
        headers: headers,
        body: {
          content: content,
          metadata: {
            contact_id: contact_id,
            account_id: @account_id,
            importance: importance,
            stored_at: Time.current.iso8601
          },
          tags: tags
        }.to_json
      )
    end

    # Retrieve relevant memories for a contact
    def recall_memories(contact_id, query: nil, limit: 10)
      search_query = query || "preferences and notes for contact #{contact_id}"

      response = HTTParty.post(
        "#{self.class.base_uri}/#{@project_id}/database/memory/search",
        headers: headers,
        body: {
          query: search_query,
          limit: limit,
          filters: {
            contact_id: contact_id,
            account_id: @account_id
          }
        }.to_json
      )

      JSON.parse(response.body)['results']
    end

    # Auto-extract and store insights from conversations
    def extract_and_store_insights(conversation)
      # Use OpenAI to extract key insights
      insights = extract_insights_with_ai(conversation)

      insights.each do |insight|
        store_memory(
          conversation.contact_id,
          insight[:content],
          importance: insight[:importance],
          tags: insight[:tags]
        )
      end
    end

    private

    def headers
      {
        'X-API-Key' => @api_key,
        'Content-Type' => 'application/json'
      }
    end

    def extract_insights_with_ai(conversation)
      # TODO: Implement OpenAI extraction
      # For now, return empty array
      []
    end
  end
end
```

**UI Integration:**
```vue
<!-- Show memory sidebar in contact view -->
<template>
  <div class="contact-memories">
    <h4>📝 Customer Context & Notes</h4>
    <p class="powered-by">Powered by ZeroDB Memory</p>

    <div v-for="memory in memories" :key="memory.id" class="memory-card">
      <p class="memory-content">{{ memory.content }}</p>
      <div class="memory-meta">
        <span class="importance" :class="memory.metadata.importance">
          {{ memory.metadata.importance }}
        </span>
        <span class="date">{{ formatDate(memory.metadata.stored_at) }}</span>
      </div>
    </div>

    <button @click="showAddMemory" class="add-memory-btn">
      + Add Note
    </button>
  </div>
</template>
```

---

### Feature 2.4: RLHF Feedback Loop

**Problem:** No way to improve AI responses based on agent feedback
**Solution:** ZeroDB RLHF API to collect feedback and improve suggestions

**Service:** `app/services/zerodb/rlhf_service.rb`

```ruby
module Zerodb
  class RlhfService
    include HTTParty
    base_uri ENV.fetch('ZERODB_API_URL', 'https://api.ainative.studio/v1/public')

    def initialize(account_id)
      @account_id = account_id
      @project_id = ENV['ZERODB_PROJECT_ID']
      @api_key = ENV['ZERODB_API_KEY']
    end

    # Log agent feedback on AI suggestion
    def log_feedback(suggestion_type:, prompt:, response:, rating:, feedback: nil, metadata: {})
      HTTParty.post(
        "#{self.class.base_uri}/#{@project_id}/database/rlhf",
        headers: headers,
        body: {
          interaction_type: suggestion_type, # 'canned_response_suggestion', 'semantic_search'
          prompt: prompt,
          response: response,
          rating: rating, # 1-5 stars
          feedback: feedback,
          metadata: metadata.merge(account_id: @account_id)
        }.to_json
      )
    end

    # Get RLHF statistics for account
    def get_stats
      response = HTTParty.get(
        "#{self.class.base_uri}/#{@project_id}/database/rlhf/stats",
        headers: headers
      )
      JSON.parse(response.body)
    end

    private

    def headers
      {
        'X-API-Key' => @api_key,
        'Content-Type' => 'application/json'
      }
    end
  end
end
```

**Frontend Feedback Widget:**
```vue
<!-- Add feedback thumbs to AI suggestions -->
<template>
  <div class="ai-suggestion">
    <p>{{ suggestion.content }}</p>
    <div class="feedback-buttons">
      <button @click="submitFeedback(5)" class="thumbs-up">👍</button>
      <button @click="submitFeedback(1)" class="thumbs-down">👎</button>
    </div>
  </div>
</template>

<script>
export default {
  methods: {
    async submitFeedback(rating) {
      await this.$axios.post('/api/v1/rlhf/feedback', {
        suggestion_type: 'canned_response_suggestion',
        prompt: this.conversationContext,
        response: this.suggestion.content,
        rating: rating,
        metadata: {
          suggestion_id: this.suggestion.id,
          conversation_id: this.conversationId
        }
      });

      this.$toast.success('Feedback recorded - helping improve AI suggestions!');
    }
  }
};
</script>
```

---

### Feature 2.5: Similar Ticket Detection

**Problem:** Duplicate/related tickets not automatically linked
**Solution:** Vector similarity to find related conversations

**Service:** `app/services/zerodb/similar_ticket_detector.rb`

```ruby
module Zerodb
  class SimilarTicketDetector
    include HTTParty
    base_uri ENV.fetch('ZERODB_API_URL', 'https://api.ainative.studio/v1/public')

    def initialize(account_id)
      @account_id = account_id
      @project_id = ENV['ZERODB_PROJECT_ID']
      @api_key = ENV['ZERODB_API_KEY']
    end

    # Find similar conversations
    def find_similar(conversation, limit: 5)
      # Generate embedding for current conversation
      query_text = conversation_text(conversation)

      response = HTTParty.post(
        "#{self.class.base_uri}/#{@project_id}/embeddings/search",
        headers: headers,
        body: {
          query: query_text,
          top_k: limit + 1, # +1 to exclude self
          namespace: "conversations_#{@account_id}",
          filter: {
            account_id: @account_id
          },
          similarity_threshold: 0.75,
          include_metadata: true
        }.to_json
      )

      results = JSON.parse(response.body)['results']
      # Exclude self
      results = results.reject { |r| r['metadata']['conversation_id'] == conversation.id }

      conversation_ids = results.map { |r| r['metadata']['conversation_id'] }
      Conversation.where(id: conversation_ids, account_id: @account_id)
    end

    private

    def headers
      {
        'X-API-Key' => @api_key,
        'Content-Type' => 'application/json'
      }
    end

    def conversation_text(conversation)
      [
        conversation.additional_attributes['subject'],
        conversation.messages.last(5).map(&:content).join(' ')
      ].join(' ')
    end
  end
end
```

**UI Widget:**
```vue
<!-- Show similar tickets sidebar -->
<template>
  <div class="similar-tickets">
    <h4>🔗 Related Conversations</h4>
    <p class="subtitle">Found {{ similarTickets.length }} similar tickets</p>

    <div v-for="ticket in similarTickets" :key="ticket.id" class="ticket-card">
      <router-link :to="`/conversations/${ticket.id}`">
        <h5>{{ ticket.subject }}</h5>
        <p class="similarity">{{ (ticket.similarity_score * 100).toFixed(0) }}% similar</p>
        <p class="status">{{ ticket.status }}</p>
      </router-link>
    </div>
  </div>
</template>
```

---

## 📈 Phase 3: ZeroDB Signup Integration (Week 7-8)

### Goal: Convert Chatwoot Users to ZeroDB Customers

### Strategy 3.1: In-App ZeroDB Branding

**Locations to Add "Powered by ZeroDB" Badges:**

1. **Semantic Search Box**
   ```html
   <div class="search-box">
     <input type="text" placeholder="Search by meaning..." />
     <span class="powered-by">
       🚀 Powered by <a href="https://zerodb.io?ref=chatwoot">ZeroDB AI</a>
     </span>
   </div>
   ```

2. **AI Suggestions Panel**
   ```html
   <div class="ai-panel">
     <h4>💡 Smart Suggestions</h4>
     <p class="powered-by">
       AI-powered by <a href="https://zerodb.io/features/embeddings">ZeroDB Embeddings</a>
     </p>
   </div>
   ```

3. **Footer Link**
   ```html
   <footer>
     <!-- existing links -->
     <a href="https://zerodb.io?ref=chatwoot">Database powered by ZeroDB</a>
   </footer>
   ```

### Strategy 3.2: Upgrade Prompts

**Banner for Heavy Users:**
```vue
<template>
  <div v-if="showUpgradeBanner" class="upgrade-banner">
    <h4>🎯 Unlock Advanced AI Features</h4>
    <p>
      You're using {{ searchCount }} AI-powered searches this month.
      Get unlimited searches, custom embeddings, and dedicated support with
      <strong>ZeroDB Pro</strong>.
    </p>
    <button @click="redirectToZeroDB" class="cta-btn">
      Upgrade to ZeroDB Pro
    </button>
  </div>
</template>
```

### Strategy 3.3: Developer Documentation

**Add `/docs/zerodb-integration.md` to Chatwoot repo:**

```markdown
# How Chatwoot Uses ZeroDB

This fork of Chatwoot uses **ZeroDB** as its AI-native database platform, enabling:

## Features Powered by ZeroDB

1. **Semantic Conversation Search** - Find conversations by meaning, not just keywords
   - Uses ZeroDB's free embeddings API (384-dim BAAI/bge-small-en-v1.5)
   - Vector storage and similarity search
   - Example: Search "customer wants refund" → finds conversations about refunds even without that exact phrase

2. **Smart Canned Response Suggestions** - AI suggests relevant responses based on context
   - ZeroDB embed-and-store API for canned response indexing
   - Semantic search to match conversation context with best responses
   - Saves agents 30% time finding right responses

3. **Agent Memory & Context** - Remembers customer preferences across conversations
   - ZeroDB Memory API for persistent context storage
   - Semantic recall of customer notes and preferences
   - Example: "Customer prefers email over phone" remembered across all conversations

4. **RLHF Feedback Loop** - Continuously improves AI suggestions
   - ZeroDB RLHF API for feedback collection
   - Track which suggestions agents accept/reject
   - Use data to fine-tune suggestion algorithms

5. **Similar Ticket Detection** - Automatically finds related conversations
   - Vector similarity search across all conversations
   - Helps agents reference past solutions
   - Reduces duplicate ticket handling

## Want to Build Your Own AI Features?

All these features use **ZeroDB's free tier**:
- Free embeddings (384-dim, unlimited)
- 10,000 free vectors
- 100,000 free events/month
- 1 GB free storage

**Get Started:**
1. Sign up at [zerodb.io/signup?ref=chatwoot](https://zerodb.io/signup?ref=chatwoot)
2. Get your API key
3. Use our open-source integration code (MIT licensed)

**Learn More:**
- [ZeroDB Documentation](https://docs.zerodb.io)
- [Embeddings API Guide](https://docs.zerodb.io/embeddings)
- [Vector Search Tutorial](https://docs.zerodb.io/vector-search)
```

### Strategy 3.4: Blog Post & Case Study

**Publish on ZeroDB blog:**

**Title:** "How We Built AI-Powered Customer Support with ZeroDB: A Chatwoot Case Study"

**Outline:**
1. **Problem:** Traditional customer support lacks AI intelligence
2. **Solution:** ZeroDB's vector database + embeddings API
3. **Implementation:** 5 AI features in 6 weeks
4. **Results:**
   - 50% faster ticket resolution (semantic search)
   - 30% time savings (smart suggestions)
   - 90% customer context retention (memory API)
5. **Technical Deep Dive:**
   - Architecture diagrams
   - Code examples (MIT licensed on GitHub)
   - Performance metrics
6. **Call to Action:**
   - Fork Chatwoot-ZeroDB on GitHub
   - Try ZeroDB free tier
   - Book demo for custom deployment

### Strategy 3.5: Pricing & Upgrade Paths

**ZeroDB Tier Recommendations in Chatwoot:**

| Chatwoot Usage | ZeroDB Tier | Monthly Cost | Features |
|----------------|-------------|--------------|----------|
| < 1,000 conversations | Free | $0 | Basic AI features |
| 1K - 10K conversations | Pro | $49 | Unlimited embeddings, 100K vectors |
| 10K - 100K conversations | Scale | $199 | Quantum features, 1M vectors |
| 100K+ conversations | Enterprise | Custom | Dedicated support, custom AI models |

**In-App Upgrade Flow:**
```
User clicks "Upgrade to Pro" →
  Redirect to https://zerodb.io/pricing?ref=chatwoot&plan=pro →
  Pre-fill account details from Chatwoot →
  One-click signup with Stripe →
  Return to Chatwoot with ZeroDB API key →
  Auto-configure ZeroDB in Chatwoot settings
```

---

## 📊 Phase 4: Metrics & Analytics (Week 9-10)

### Key Metrics to Track

**ZeroDB Usage Dashboard (in Chatwoot Admin):**

```ruby
# app/controllers/super_admin/zerodb_analytics_controller.rb
class SuperAdmin::ZerodbAnalyticsController < SuperAdmin::ApplicationController
  def index
    @stats = fetch_zerodb_stats
  end

  private

  def fetch_zerodb_stats
    response = HTTParty.get(
      "#{ENV['ZERODB_API_URL']}/#{ENV['ZERODB_PROJECT_ID']}/usage",
      headers: { 'X-API-Key' => ENV['ZERODB_API_KEY'] }
    )

    JSON.parse(response.body)
  end
end
```

**Metrics to Display:**
- Vector count: `{{ stats.vectors_count }} / 100,000`
- Embedding API calls: `{{ stats.embedding_calls }} (all free!)`
- Semantic searches: `{{ stats.search_queries }}`
- Memory records: `{{ stats.memory_usage_mb }} MB`
- RLHF feedback count: `{{ stats.rlhf_interactions }}`
- Monthly cost: `${{ calculate_cost(stats) }}`

**Sample Dashboard:**
```vue
<template>
  <div class="zerodb-dashboard">
    <h2>🚀 ZeroDB Usage & Performance</h2>

    <div class="metrics-grid">
      <metric-card
        title="Conversations Indexed"
        :value="stats.vectors_count"
        :max="100000"
        icon="📊"
      />

      <metric-card
        title="Embeddings Generated"
        :value="stats.embedding_calls"
        subtitle="All FREE!"
        icon="🎯"
      />

      <metric-card
        title="Semantic Searches"
        :value="stats.search_queries"
        trend="+25% this week"
        icon="🔍"
      />

      <metric-card
        title="Agent Memories Stored"
        :value="stats.memory_count"
        subtitle="Across all conversations"
        icon="🧠"
      />
    </div>

    <div class="cost-summary">
      <h3>Monthly Cost Breakdown</h3>
      <table>
        <tr>
          <td>Embeddings API (384-dim)</td>
          <td class="free">FREE</td>
        </tr>
        <tr>
          <td>Vector Storage ({{ stats.vectors_count }} vectors)</td>
          <td>${{ (stats.vectors_count * 0.001).toFixed(2) }}</td>
        </tr>
        <tr>
          <td>Search Queries ({{ stats.search_queries }} / month)</td>
          <td>${{ (stats.search_queries * 0.01).toFixed(2) }}</td>
        </tr>
        <tr class="total">
          <td><strong>Total Monthly Cost</strong></td>
          <td><strong>${{ totalCost }}</strong></td>
        </tr>
      </table>

      <button @click="upgradeToZeroDB" class="upgrade-btn">
        Upgrade to ZeroDB Pro for $49/month
      </button>
    </div>
  </div>
</template>
```

---

## 🎨 Phase 5: Branding & Marketing (Week 11-12)

### Rebrand as "Chatwoot-ZeroDB Edition"

**Changes:**

1. **README.md Updates:**
```markdown
# Chatwoot - ZeroDB Edition

> AI-native customer support platform powered by ZeroDB

This is a lightweight fork of [Chatwoot](https://github.com/chatwoot/chatwoot)
enhanced with **ZeroDB**'s AI-native database capabilities.

## 🚀 What's New in ZeroDB Edition?

### AI-Powered Features (Not in Original Chatwoot)
✅ **Semantic Conversation Search** - Find tickets by meaning, not just keywords
✅ **Smart Response Suggestions** - AI recommends best canned responses
✅ **Agent Memory** - Remember customer preferences across conversations
✅ **Similar Ticket Detection** - Automatically link related conversations
✅ **RLHF Feedback Loop** - Continuously improve AI suggestions

### Powered by ZeroDB
- 🎯 Free embeddings (384-dim BAAI/bge-small-en-v1.5)
- 🚀 Vector search with semantic similarity
- 🧠 Agent memory storage
- 📊 RLHF feedback collection
- ⚡ 50% faster semantic search vs. traditional full-text

## 📦 Deployment

### One-Click Deploy with ZeroDB

[![Deploy to Railway](https://railway.app/button.svg)](https://railway.app/template/...)

Includes:
- Pre-configured ZeroDB project
- Dedicated PostgreSQL instance
- All AI features enabled
- $5 credit for ZeroDB (first month free!)

### Manual Deployment

1. **Sign up for ZeroDB** (free tier available)
   ```bash
   curl -X POST https://api.ainative.studio/v1/public/auth/register \
     -d email=you@example.com -d password=secure_pass
   ```

2. **Get API credentials**
   ```bash
   # Get your API key and project ID from dashboard
   https://console.zerodb.io/api-keys
   ```

3. **Set environment variables**
   ```bash
   ZERODB_API_KEY=your_api_key
   ZERODB_PROJECT_ID=your_project_id
   ZERODB_POSTGRES_HOST=postgres-xxx.railway.app
   # ... (see .env.example)
   ```

4. **Deploy Chatwoot-ZeroDB**
   ```bash
   git clone https://github.com/AINative-Studio/chatwoot-zerodb
   cd chatwoot-zerodb
   bundle install
   rails db:migrate
   rails s
   ```

## 💰 Pricing

### Chatwoot-ZeroDB is Free & Open Source
- MIT License (same as Chatwoot)
- Self-host on your infrastructure
- No vendor lock-in

### ZeroDB Costs (Pay-as-You-Grow)
- **Free Tier:** 10K vectors, 100K events/month, 1GB storage
- **Pro Tier:** $49/month for 100K vectors, unlimited embeddings
- **Scale Tier:** $199/month for 1M vectors, quantum features
- **Enterprise:** Custom pricing for 100M+ vectors

**Typical Costs:**
- Small team (1K conversations/month): **$0 - $10/month**
- Medium team (10K conversations/month): **$20 - $49/month**
- Large team (100K conversations/month): **$199/month**

## 🤝 Contributing

We welcome contributions! This fork maintains compatibility with upstream Chatwoot.

**ZeroDB Integration PRs:**
- See `docs/zerodb-integration.md` for architecture
- All ZeroDB code in `app/services/zerodb/`
- Tests required for new features

## 📚 Documentation

- [Chatwoot Docs](https://www.chatwoot.com/docs)
- [ZeroDB Integration Guide](docs/zerodb-integration.md)
- [API Reference](docs/api-reference.md)
- [Deployment Guide](docs/deployment.md)

## 🙏 Credits

- **Chatwoot Team** - Original open-source platform
- **ZeroDB** - AI-native database infrastructure
- **Contributors** - See [CONTRIBUTORS.md](CONTRIBUTORS.md)

## 📜 License

MIT License (same as Chatwoot)

## 🔗 Links

- **Chatwoot-ZeroDB Demo:** https://demo.chatwoot-zerodb.com
- **ZeroDB Homepage:** https://zerodb.io
- **Support:** https://github.com/AINative-Studio/chatwoot-zerodb/issues
```

2. **Landing Page (GitHub Pages):**

Create `docs/index.html` for GitHub Pages site:

```html
<!DOCTYPE html>
<html>
<head>
  <title>Chatwoot-ZeroDB: AI-Native Customer Support</title>
  <!-- Meta tags for SEO -->
</head>
<body>
  <header>
    <h1>Chatwoot + ZeroDB = AI-Powered Customer Support</h1>
    <p>Open-source customer support platform enhanced with AI database</p>
    <a href="https://github.com/AINative-Studio/chatwoot-zerodb" class="cta">
      View on GitHub
    </a>
    <a href="https://demo.chatwoot-zerodb.com" class="cta-secondary">
      Try Demo
    </a>
  </header>

  <section class="features">
    <h2>New AI Features (Powered by ZeroDB)</h2>
    <div class="feature-grid">
      <div class="feature">
        <h3>🔍 Semantic Search</h3>
        <p>Find conversations by meaning, not just keywords</p>
      </div>
      <div class="feature">
        <h3>💡 Smart Suggestions</h3>
        <p>AI recommends best canned responses</p>
      </div>
      <div class="feature">
        <h3>🧠 Agent Memory</h3>
        <p>Remember customer preferences forever</p>
      </div>
      <!-- ... more features -->
    </div>
  </section>

  <section class="demo">
    <h2>See It In Action</h2>
    <video controls>
      <source src="demo.mp4" type="video/mp4">
    </video>
  </section>

  <section class="testimonials">
    <h2>Why Teams Love Chatwoot-ZeroDB</h2>
    <!-- Add testimonials -->
  </section>

  <section class="cta-final">
    <h2>Ready to Get Started?</h2>
    <a href="https://github.com/AINative-Studio/chatwoot-zerodb" class="cta-large">
      Fork on GitHub (Free & Open Source)
    </a>
    <a href="https://zerodb.io/signup?ref=chatwoot" class="cta-large-secondary">
      Sign Up for ZeroDB (Free Tier)
    </a>
  </section>
</body>
</html>
```

3. **Demo Video (2-minute walkthrough):**

**Script:**
```
00:00 - "Hi, I'm demoing Chatwoot-ZeroDB, an AI-enhanced customer support platform"
00:10 - Show semantic search: "customer wants refund" → finds relevant conversations
00:30 - Show smart suggestions: AI recommends canned responses based on context
00:50 - Show agent memory: Past customer notes automatically appear
01:10 - Show similar tickets: Related conversations automatically linked
01:30 - Show ZeroDB dashboard: Usage metrics and cost savings
01:50 - "All powered by ZeroDB's free embeddings API - fork it on GitHub!"
```

---

## 📈 Success Metrics & KPIs

### Week 1-2 (Migration Phase)
- [ ] ZeroDB Dedicated PostgreSQL provisioned
- [ ] All Chatwoot data migrated successfully
- [ ] All existing features working (100% parity)
- [ ] Zero downtime during migration

### Week 3-6 (AI Features Phase)
- [ ] Semantic search 50% faster than keyword search
- [ ] Smart suggestions save agents 30% time
- [ ] Agent memory retention rate: 90%+
- [ ] RLHF feedback collection: 100+ interactions/week
- [ ] Similar ticket detection accuracy: 85%+

### Week 7-12 (Signup Generation Phase)
- [ ] GitHub stars: 500+ in first month
- [ ] ZeroDB signups via Chatwoot referral: 10+ /month
- [ ] Demo site traffic: 1,000+ visitors/month
- [ ] Blog post views: 5,000+ views
- [ ] Developer documentation completeness: 100%

### 6-Month Goals
- [ ] ZeroDB signups via Chatwoot: 100+ total
- [ ] Community forks: 50+
- [ ] Production deployments: 10+
- [ ] Revenue generated for ZeroDB: $5,000+/month from Chatwoot users

---

## 🚧 Risk Mitigation

### Technical Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| ZeroDB API downtime | High | Cache responses locally, fallback to keyword search |
| Embedding API rate limits | Medium | Implement queue system, batch requests |
| Data migration fails | High | Comprehensive backup strategy, rollback plan |
| Performance degradation | Medium | Load testing, caching layer, CDN for static assets |
| Upstream Chatwoot changes | Low | Regular merge from upstream, compatibility testing |

### Business Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Low adoption | High | Strong marketing, compelling demos, free tier |
| ZeroDB costs too high | Medium | Transparent pricing calculator in app |
| Chatwoot license conflict | Low | MIT license maintained, proper attribution |
| Competition from Chatwoot | Low | Contribute features back to upstream |

---

## 💰 Cost Analysis

### Development Costs (One-Time)

| Phase | Hours | Rate | Cost |
|-------|-------|------|------|
| Phase 1: Migration | 40h | $100/h | $4,000 |
| Phase 2: AI Features | 120h | $100/h | $12,000 |
| Phase 3: Signup Integration | 40h | $100/h | $4,000 |
| Phase 4: Metrics Dashboard | 20h | $100/h | $2,000 |
| Phase 5: Branding/Marketing | 40h | $100/h | $4,000 |
| **Total Development** | **260h** | | **$26,000** |

### Ongoing Costs (Monthly)

| Service | Tier | Cost |
|---------|------|------|
| ZeroDB Dedicated PostgreSQL | Standard-4 | $75 |
| ZeroDB Vector Storage | 10K vectors | $10 |
| ZeroDB Search Queries | 1K/day | $10 |
| Domain & Hosting | GitHub Pages | $0 |
| **Total Monthly** | | **$95** |

### Revenue Projections (6 Months)

| Month | New Signups | Pro Tier ($49) | Scale Tier ($199) | Revenue |
|-------|-------------|----------------|-------------------|---------|
| 1 | 5 | 3 | 2 | $545 |
| 2 | 10 | 6 | 4 | $1,090 |
| 3 | 15 | 9 | 6 | $1,635 |
| 4 | 20 | 12 | 8 | $2,180 |
| 5 | 25 | 15 | 10 | $2,725 |
| 6 | 30 | 18 | 12 | $3,270 |
| **Total** | **105** | | | **$11,445** |

**ROI Calculation:**
- Total Investment: $26,000 (dev) + $570 (6mo hosting) = $26,570
- 6-Month Revenue: $11,445
- Break-even: ~Month 14
- Year 1 Revenue: ~$25,000

---

## 📋 Implementation Checklist

### Pre-Launch (Week 1-2)
- [ ] Fork Chatwoot repository to `AINative-Studio/chatwoot-zerodb`
- [ ] Create ZeroDB account and project
- [ ] Provision dedicated PostgreSQL instance
- [ ] Migrate local Chatwoot data to ZeroDB
- [ ] Update database.yml configuration
- [ ] Test all existing Chatwoot features
- [ ] Run full test suite (RSpec)
- [ ] Document migration process

### AI Features Development (Week 3-6)
- [ ] Implement Semantic Search Service
- [ ] Implement Smart Canned Response Suggester
- [ ] Implement Agent Memory Service
- [ ] Implement RLHF Feedback Service
- [ ] Implement Similar Ticket Detector
- [ ] Add frontend UI for all features
- [ ] Write integration tests
- [ ] Create API documentation
- [ ] Performance testing

### Signup Integration (Week 7-8)
- [ ] Add "Powered by ZeroDB" badges
- [ ] Create upgrade prompts/banners
- [ ] Write developer documentation
- [ ] Create pricing calculator
- [ ] Implement one-click signup flow
- [ ] Test referral tracking
- [ ] Create ZeroDB dashboard in admin

### Marketing & Launch (Week 9-12)
- [ ] Update README with ZeroDB branding
- [ ] Create GitHub Pages landing page
- [ ] Record 2-minute demo video
- [ ] Write blog post/case study
- [ ] Submit to Product Hunt
- [ ] Post on HackerNews
- [ ] Share on Twitter/LinkedIn
- [ ] Create documentation site
- [ ] Set up analytics tracking

### Post-Launch (Ongoing)
- [ ] Monitor ZeroDB signups via referral
- [ ] Collect user feedback
- [ ] Fix bugs and issues
- [ ] Merge upstream Chatwoot changes
- [ ] Add new AI features
- [ ] Create tutorial videos
- [ ] Engage with community
- [ ] Monthly performance reports

---

## 🎓 Learning Resources

### For Development Team

**ZeroDB Documentation:**
- [ZeroDB Developer Guide](/Users/aideveloper/core/docs/Zero-DB/ZeroDB_Public_Developer_Guide.md)
- [ZeroDB Tools Quick Reference](/Users/aideveloper/core/docs/ZERODB_TOOLS_QUICK_REFERENCE.md)
- [Embeddings API Tutorial](https://docs.zerodb.io/embeddings)
- [Vector Search Best Practices](https://docs.zerodb.io/vector-search)

**Chatwoot Documentation:**
- [Chatwoot Architecture Analysis](/Users/aideveloper/core/docs/CHATWOOT_ARCHITECTURE_ANALYSIS.md)
- [Chatwoot-ZeroDB Integration Plan](/Users/aideveloper/core/docs/CHATWOOT_ZERODB_INTEGRATION_PLAN.md)
- [Chatwoot Quick Reference](/Users/aideveloper/core/docs/CHATWOOT_QUICK_REFERENCE.md)
- [Official Chatwoot Docs](https://www.chatwoot.com/docs)

**Ruby on Rails:**
- [Rails Guides](https://guides.rubyonrails.org/)
- [ActiveRecord Basics](https://guides.rubyonrails.org/active_record_basics.html)
- [Testing with RSpec](https://rspec.info/)

---

## 🤝 Team & Roles

### Recommended Team Structure

| Role | Responsibilities | Time Commitment |
|------|-----------------|-----------------|
| **Tech Lead** | Architecture decisions, code review, ZeroDB integration | Full-time (12 weeks) |
| **Backend Developer** | Rails services, database migration, API integration | Full-time (10 weeks) |
| **Frontend Developer** | Vue.js UI components, AI feature interfaces | Full-time (6 weeks) |
| **DevOps Engineer** | Deployment, monitoring, performance tuning | Part-time (4 weeks) |
| **Marketing Manager** | Content creation, community engagement, demos | Part-time (8 weeks) |
| **QA Engineer** | Testing, bug tracking, documentation | Part-time (6 weeks) |

---

## 📅 Timeline Summary

| Week | Phase | Deliverables |
|------|-------|-------------|
| 1-2 | Migration | ZeroDB PostgreSQL live, data migrated |
| 3-4 | AI Features #1-2 | Semantic search + Smart suggestions |
| 5-6 | AI Features #3-5 | Memory + RLHF + Similar tickets |
| 7-8 | Signup Integration | Branding, upgrade flows, tracking |
| 9-10 | Metrics & Analytics | Dashboard, cost calculator |
| 11-12 | Marketing & Launch | Blog post, demo video, launch campaign |

**Total Timeline: 12 weeks (3 months)**

---

## 🎯 Next Steps

### Immediate Actions (This Week)

1. **Fork Chatwoot Repository**
   ```bash
   # Navigate to https://github.com/chatwoot/chatwoot
   # Click "Fork" button
   # Clone to AINative-Studio/chatwoot-zerodb
   ```

2. **Create ZeroDB Account & Project**
   ```bash
   curl -X POST https://api.ainative.studio/v1/public/auth/register \
     -H "Content-Type: application/json" \
     -d '{
       "email": "chatwoot@ainative.studio",
       "password": "SECURE_PASSWORD_HERE"
     }'
   ```

3. **Set Up Development Environment**
   ```bash
   cd /Users/aideveloper
   git clone https://github.com/AINative-Studio/chatwoot-zerodb.git
   cd chatwoot-zerodb
   bundle install
   # Configure .env with ZeroDB credentials
   ```

4. **Review All Documentation**
   - Read CHATWOOT_ARCHITECTURE_ANALYSIS.md
   - Read CHATWOOT_ZERODB_INTEGRATION_PLAN.md
   - Review ZeroDB Public Developer Guide
   - Understand current Chatwoot codebase

5. **Create Project Plan in GitHub**
   - Create GitHub Project board
   - Add all tasks from this plan as issues
   - Assign to team members
   - Set milestones for each phase

---

## 📞 Contact & Support

### Internal Team
- **Project Lead:** [Name] - [email]
- **Tech Lead:** [Name] - [email]
- **Backend Dev:** [Name] - [email]

### External Support
- **ZeroDB Support:** support@ainative.studio
- **Chatwoot Community:** https://discord.gg/cJXdrwS
- **GitHub Issues:** https://github.com/AINative-Studio/chatwoot-zerodb/issues

---

**Document Version:** 1.0
**Last Updated:** December 5, 2025
**Status:** Ready for Implementation
**Approved By:** [Approver Name]

---

## Appendix A: Environment Variables Reference

```bash
# .env.example for Chatwoot-ZeroDB

# === ZeroDB Configuration ===
ZERODB_API_KEY=your_api_key_here
ZERODB_PROJECT_ID=your_project_id_here
ZERODB_API_URL=https://api.ainative.studio/v1/public

# ZeroDB Dedicated PostgreSQL
ZERODB_POSTGRES_HOST=postgres-xxx.railway.app
ZERODB_POSTGRES_PORT=5432
ZERODB_POSTGRES_DATABASE=chatwoot_production
ZERODB_POSTGRES_USERNAME=postgres_user_xxx
ZERODB_POSTGRES_PASSWORD=generated_password

# === Chatwoot Configuration (unchanged) ===
SECRET_KEY_BASE=generate_with_rails_secret
FRONTEND_URL=https://app.chatwoot.com
INSTALLATION_NAME=Chatwoot-ZeroDB

# Redis
REDIS_URL=redis://localhost:6379

# Rails
RAILS_ENV=production
RAILS_MAX_THREADS=5

# ... (rest of Chatwoot env vars)
```

---

## Appendix B: Cost Calculator Tool

**Embed in Chatwoot Admin Dashboard:**

```html
<div class="zerodb-cost-calculator">
  <h3>💰 Estimate Your ZeroDB Costs</h3>

  <label>
    Conversations per month:
    <input type="number" v-model="conversationsPerMonth" />
  </label>

  <label>
    Agent searches per day:
    <input type="number" v-model="searchesPerDay" />
  </label>

  <div class="cost-breakdown">
    <h4>Estimated Monthly Cost: ${{ totalCost }}</h4>

    <table>
      <tr>
        <td>Embeddings ({{ embeddingCount }} calls)</td>
        <td class="free">FREE</td>
      </tr>
      <tr>
        <td>Vector Storage ({{ vectorCount }} vectors)</td>
        <td>${{ vectorCost }}</td>
      </tr>
      <tr>
        <td>Search Queries ({{ searchCount }} searches)</td>
        <td>${{ searchCost }}</td>
      </tr>
      <tr>
        <td>Memory Storage ({{ memoryMB }} MB)</td>
        <td>${{ memoryCost }}</td>
      </tr>
      <tr class="total">
        <td><strong>Total</strong></td>
        <td><strong>${{ totalCost }}</strong></td>
      </tr>
    </table>

    <p class="recommendation">
      Recommended Tier: <strong>{{ recommendedTier }}</strong>
    </p>
  </div>
</div>
```

---

**END OF MASTER PLAN**
