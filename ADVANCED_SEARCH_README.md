# Advanced Search System

## Overview

The Advanced Search System provides powerful, fast search capabilities across conversations, messages, and contacts with comprehensive filtering options. Designed to maintain p95 response times ≤ 300ms on staging data.

## Performance Targets

- **p95 Response Time**: ≤ 300ms
- **p99 Response Time**: ≤ 500ms  
- **Throughput**: 100+ concurrent searches
- **Accuracy**: Full-text search with fuzzy matching

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Search UI     │───▶│  API Controller  │───▶│ Search Service  │
│                 │    │                  │    │                 │
│ - Query Input   │    │ - Validation     │    │ - Query Builder │
│ - Filter UI     │    │ - Pagination     │    │ - Performance   │
│ - Results       │    │ - Caching        │    │ - Monitoring    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                               ┌─────────────────────────┼─────────────────────────┐
                               │                         │                         │
                       ┌───────▼────────┐    ┌──────────▼──────────┐    ┌────────▼────────┐
                       │  PostgreSQL    │    │   Elasticsearch     │    │     Redis       │
                       │                │    │                     │    │                 │
                       │ - GIN Indexes  │    │ - Full-text Search  │    │ - Query Cache   │
                       │ - Trigram      │    │ - Fuzzy Matching    │    │ - Performance   │
                       │ - Composite    │    │ - Analytics         │    │ - Metrics       │
                       └────────────────┘    └─────────────────────┘    └─────────────────┘
```

## Database Indexes

### Performance-Optimized Indexes

```sql
-- Conversations search indexes
CREATE INDEX idx_conversations_search_filter_combo 
ON conversations (account_id, inbox_id, status, assignee_id, created_at);

CREATE INDEX idx_conversations_account_status_created_at 
ON conversations (account_id, status, created_at);

CREATE INDEX idx_conversations_account_team_status_created 
ON conversations (account_id, team_id, status, created_at);

-- Messages search indexes  
CREATE INDEX idx_messages_account_conv_type_created 
ON messages (account_id, conversation_id, message_type, created_at);

CREATE INDEX idx_messages_search_filter_combo 
ON messages (account_id, message_type, private, created_at);

-- Full-text search indexes
CREATE INDEX idx_messages_content_trgm 
ON messages USING gin (content gin_trgm_ops);

CREATE INDEX idx_contacts_search_trgm 
ON contacts USING gin ((name || ' ' || COALESCE(email, '') || ' ' || COALESCE(phone_number, '')) gin_trgm_ops);

-- JSON attribute indexes
CREATE INDEX idx_conversations_additional_attrs 
ON conversations USING gin (additional_attributes);

CREATE INDEX idx_messages_additional_attrs 
ON messages USING gin (additional_attributes);
```

### Index Usage Examples

```sql
-- Fast conversation search with filters
SELECT * FROM conversations 
WHERE account_id = 1 
  AND status = 'open' 
  AND assignee_id = 123 
  AND created_at >= '2024-01-01'
ORDER BY created_at DESC;
-- Uses: idx_conversations_search_filter_combo

-- Trigram-based fuzzy contact search
SELECT * FROM contacts 
WHERE (name || ' ' || COALESCE(email, '') || ' ' || COALESCE(phone_number, '')) % 'john smith'
ORDER BY similarity(name, 'john smith') DESC;
-- Uses: idx_contacts_search_trgm

-- JSON attribute search
SELECT * FROM conversations 
WHERE additional_attributes @> '{"campaign_id": "123"}';
-- Uses: idx_conversations_additional_attrs
```

## API Endpoints

### Search Endpoints

```bash
# Universal search across all types
GET /api/v1/accounts/:account_id/advanced_search
GET /api/v1/accounts/:account_id/advanced_search?q=search_term&status=open&page=1

# Type-specific searches
GET /api/v1/accounts/:account_id/advanced_search/conversations
GET /api/v1/accounts/:account_id/advanced_search/messages  
GET /api/v1/accounts/:account_id/advanced_search/contacts

# Utility endpoints
GET /api/v1/accounts/:account_id/advanced_search/suggestions?q=partial_term
GET /api/v1/accounts/:account_id/advanced_search/filters
```

### Filter Parameters

#### Basic Parameters
- `q` - Search query string
- `page` - Page number (default: 1)
- `per_page` - Results per page (default: 20, max: 100)

#### Filter Arrays (comma-separated)
- `channel_types` - Channel types to filter by
- `inbox_ids` - Specific inboxes
- `agent_ids` - Assigned agents
- `team_ids` - Teams
- `labels` - Labels/tags
- `status` - Conversation status (open, resolved, pending, snoozed)
- `priority` - Priority levels (low, medium, high, urgent)
- `message_types` - Message types (incoming, outgoing, activity, template)
- `sender_types` - Sender types (Contact, User)
- `sentiment` - Sentiment analysis (positive, negative, neutral)
- `sla_status` - SLA status (active, hit, missed, active_with_misses)

#### Date Filters
- `date_from` - Start date (YYYY-MM-DD)
- `date_to` - End date (YYYY-MM-DD)

#### Boolean Filters
- `has_attachments` - Messages with attachments only
- `unread_only` - Unread conversations only
- `assigned_only` - Assigned conversations only
- `unassigned_only` - Unassigned conversations only

#### Advanced Filters
- `custom_attributes` - JSON string for custom attribute search

## Usage Examples

### Basic Text Search

```javascript
// JavaScript API usage
import AdvancedSearchAPI from 'dashboard/api/advancedSearch';

// Simple search
const results = await AdvancedSearchAPI.search({
  q: 'refund request'
});

// Search with filters
const results = await AdvancedSearchAPI.conversations({
  q: 'billing issue',
  status: ['open', 'pending'],
  priority: ['high', 'urgent'],
  date_from: '2024-01-01'
});
```

### Advanced Filtering

```javascript
// Complex search with multiple filters
const searchParams = {
  q: 'payment failed',
  channel_types: ['email', 'webchat'],
  agent_ids: [1, 2, 3],
  labels: ['billing', 'urgent'],
  has_attachments: true,
  date_from: '2024-01-01',
  date_to: '2024-01-31'
};

const results = await AdvancedSearchAPI.conversations(searchParams);
```

### Saved Searches

```javascript
// Save a search
const savedSearch = await AdvancedSearchAPI.createSavedSearch({
  name: 'High Priority Billing Issues',
  description: 'All high priority conversations about billing',
  search_type: 'conversations',
  query: 'billing payment',
  filters: {
    priority: ['high', 'urgent'],
    labels: ['billing'],
    status: ['open']
  }
});

// Load saved searches
const savedSearches = await AdvancedSearchAPI.getSavedSearches();

// Use a saved search
const results = await AdvancedSearchAPI.conversations(savedSearch.formatted_filters);
```

### Batch Search

```javascript
// Search multiple types simultaneously
const batchResults = await AdvancedSearchAPI.batchSearch([
  { type: 'conversations', params: { q: 'refund', status: ['open'] } },
  { type: 'contacts', params: { q: 'john@example.com' } },
  { type: 'messages', params: { q: 'urgent', has_attachments: true } }
]);
```

## Performance Monitoring

### Built-in Monitoring

The system includes comprehensive performance monitoring:

```javascript
// Performance tracking is automatic
const results = await AdvancedSearchAPI.performanceSearch('conversations', {
  q: 'complex search query'
});
// Automatically logs: "Search completed in 245.67ms"

// Access performance metrics
console.log(results.data.meta.execution_time); // 245.67
```

### Slow Query Detection

Searches exceeding 300ms are automatically:
- Logged with full parameters
- Tracked in Redis for analysis
- Sent to error monitoring (Sentry/Bugsnag)
- Alerted via Slack (if configured)

### Monitoring Endpoints

```bash
# Get search analytics
GET /api/v1/accounts/:account_id/advanced_search/analytics?timeframe=7d

# Get slow queries
GET /api/v1/accounts/:account_id/advanced_search/slow_queries?limit=50
```

## Search Strategies

### Text Search Methods

1. **Basic ILIKE Search** (default)
   - Fast for simple queries
   - Case-insensitive
   - No fuzzy matching

2. **GIN Full-Text Search** (enabled via feature flag)
   ```sql
   -- Uses PostgreSQL's built-in full-text search
   SELECT * FROM messages WHERE content @@ plainto_tsquery('search terms');
   ```

3. **Trigram Fuzzy Search** (for typo tolerance)
   ```sql
   -- Handles typos and partial matches
   SELECT * FROM contacts WHERE name % 'john smth';
   ```

4. **Elasticsearch Integration** (when available)
   - Advanced relevance scoring
   - Synonym support
   - Faceted search

### Query Optimization

```javascript
// Optimized search patterns

// 1. Use specific filters to reduce dataset
const results = await AdvancedSearchAPI.conversations({
  inbox_ids: [1, 2],      // Filter first
  status: ['open'],       // Then status
  q: 'search term'        // Finally text search
});

// 2. Use date ranges to limit scope
const results = await AdvancedSearchAPI.messages({
  date_from: '2024-01-01',  // Limit time range
  date_to: '2024-01-31',
  q: 'search term'
});

// 3. Paginate for large result sets
const results = await AdvancedSearchAPI.search({
  q: 'popular term',
  page: 1,
  per_page: 20            // Keep reasonable page size
});
```

## Configuration

### Feature Flags

Enable advanced features via account settings:

```ruby
# Enable GIN full-text search
account.enable_features!('search_with_gin')

# Enable trigram fuzzy search
account.enable_features!('trigram_search')

# Enable advanced search UI
account.enable_features!('advanced_search')
```

### Environment Variables

```bash
# Performance monitoring
SLACK_PERFORMANCE_WEBHOOK=https://hooks.slack.com/services/...

# Elasticsearch (optional)
ELASTICSEARCH_URL=http://localhost:9200

# Redis (for caching and metrics)
REDIS_URL=redis://localhost:6379

# Search performance thresholds
SEARCH_SLOW_THRESHOLD_MS=300
SEARCH_VERY_SLOW_THRESHOLD_MS=1000
```

### Database Configuration

```sql
-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS btree_gin;

-- Update statistics for better query planning
ANALYZE conversations, messages, contacts;

-- Configure autovacuum for search tables
ALTER TABLE messages SET (autovacuum_vacuum_scale_factor = 0.1);
ALTER TABLE conversations SET (autovacuum_vacuum_scale_factor = 0.2);
```

## Troubleshooting

### Common Performance Issues

1. **Slow Searches (> 300ms)**
   ```sql
   -- Check index usage
   EXPLAIN (ANALYZE, BUFFERS) 
   SELECT * FROM conversations 
   WHERE account_id = 1 AND status = 'open' 
   ORDER BY created_at DESC;
   
   -- Look for:
   -- - Sequential scans (bad)
   -- - Index scans (good)  
   -- - High buffer reads (indicates missing indexes)
   ```

2. **High Memory Usage**
   ```sql
   -- Monitor work_mem usage
   SHOW work_mem;
   
   -- Increase if needed for sorting/aggregation
   SET work_mem = '256MB';
   ```

3. **Lock Contention**
   ```sql
   -- Check for blocking queries
   SELECT * FROM pg_stat_activity 
   WHERE state = 'active' AND query LIKE '%search%';
   ```

### Debugging Tools

```ruby
# Rails console debugging
search = AdvancedSearchService.new(
  current_user: User.first,
  current_account: Account.first,
  search_type: 'conversations',
  query: 'debug search'
)

result = search.perform
puts "Execution time: #{search.execution_time}ms"
puts "Total results: #{search.total_count}"
```

### Performance Benchmarking

```bash
# Benchmark search performance
curl -w "@curl-format.txt" \
  -H "Authorization: Bearer $TOKEN" \
  "http://localhost:3000/api/v1/accounts/1/advanced_search?q=test"

# Where curl-format.txt contains:
#      time_namelookup:  %{time_namelookup}\n
#         time_connect:  %{time_connect}\n
#      time_appconnect:  %{time_appconnect}\n
#     time_pretransfer:  %{time_pretransfer}\n
#        time_redirect:  %{time_redirect}\n
#   time_starttransfer:  %{time_starttransfer}\n
#                      ----------\n
#           time_total:  %{time_total}\n
```

## Migration Guide

### Upgrading from Basic Search

1. **Run Migrations**
   ```bash
   rails db:migrate
   ```

2. **Build Indexes** (run during low traffic)
   ```sql
   -- Create indexes concurrently to avoid downtime
   CREATE INDEX CONCURRENTLY idx_messages_content_trgm 
   ON messages USING gin (content gin_trgm_ops);
   ```

3. **Enable Features**
   ```ruby
   # Gradually enable for accounts
   Account.find(123).enable_features!('advanced_search')
   ```

4. **Monitor Performance**
   - Watch slow query logs
   - Monitor response times
   - Check Redis metrics

### Data Migration

```ruby
# Migrate existing search data
class MigrateSearchData < ActiveRecord::Migration[7.0]
  def up
    # Update search statistics
    execute "ANALYZE conversations, messages, contacts;"
    
    # Rebuild search indexes if needed
    execute "REINDEX INDEX CONCURRENTLY idx_messages_content_trgm;"
  end
end
```

## Security Considerations

### Access Control

```ruby
# Search respects existing permissions
class AdvancedSearchService
  def build_conversation_scope
    scope = current_account.conversations
    
    # Apply inbox-based permissions
    unless is_admin?
      allowed_inbox_ids = current_user.assigned_inboxes.pluck(:id)
      scope = scope.where(inbox_id: allowed_inbox_ids)
    end
    
    scope
  end
end
```

### Input Sanitization

```ruby
# Query sanitization prevents injection
def sanitize_for_tsquery(query)
  # Remove special characters that could break tsquery
  query.gsub(/[^\w\s]/, ' ').strip.split.join(' & ')
end
```

### Rate Limiting

```ruby
# Implement rate limiting for search endpoints
class AdvancedSearchController < ApplicationController
  before_action :check_rate_limit
  
  private
  
  def check_rate_limit
    # Allow 30 searches per minute per user
    key = "search_rate_limit:#{Current.user.id}"
    current_count = Rails.cache.increment(key, 1, expires_in: 1.minute)
    
    if current_count > 30
      render json: { error: 'Rate limit exceeded' }, status: :too_many_requests
    end
  end
end
```

## API Response Format

### Successful Response

```json
{
  "results": {
    "conversations": [
      {
        "id": 123,
        "display_id": 456,
        "status": "open",
        "created_at": "2024-01-01T10:00:00Z",
        "contact": {
          "id": 789,
          "name": "John Doe",
          "email": "john@example.com"
        },
        "assignee": {
          "id": 101,
          "name": "Agent Smith"
        },
        "inbox": {
          "id": 1,
          "name": "Support"
        }
      }
    ],
    "messages": [...],
    "contacts": [...]
  },
  "meta": {
    "execution_time": 245.67,
    "total_results": 150,
    "page": 1,
    "per_page": 20,
    "filters_applied": 3
  },
  "applied_filters": {
    "status": ["open"],
    "priority": ["high"],
    "date_from": "2024-01-01"
  },
  "suggestions": [
    {
      "type": "contact",
      "text": "John Doe", 
      "subtitle": "john@example.com"
    }
  ]
}
```

### Error Response

```json
{
  "error": "Query too long: maximum 500 characters allowed",
  "code": "QUERY_TOO_LONG",
  "details": {
    "max_length": 500,
    "provided_length": 750
  }
}
```

## Best Practices

### For Developers

1. **Use Appropriate Indexes**
   - Always include account_id in multi-column indexes
   - Order index columns by selectivity (most selective first)
   - Use partial indexes for boolean filters

2. **Optimize Queries**
   - Filter before full-text search
   - Use LIMIT appropriately
   - Avoid SELECT * in production

3. **Monitor Performance**
   - Log slow queries automatically
   - Set up alerting for p95 > 300ms
   - Profile queries in staging

### For Users

1. **Effective Search**
   - Use specific terms over generic ones
   - Combine filters to narrow results
   - Use date ranges for recent searches

2. **Save Frequent Searches**
   - Create saved searches for repeated queries
   - Use descriptive names
   - Share with team members

3. **Understand Limitations**
   - Search is limited to last 6 months for non-admins
   - Complex queries may be slower
   - Results are paginated

## Monitoring Dashboard

### Key Metrics

- **Search Volume**: Searches per hour/day
- **Performance**: p95, p99 response times  
- **Error Rate**: Failed searches percentage
- **Popular Queries**: Most searched terms
- **Slow Queries**: Searches > 300ms

### Grafana Dashboard Example

```json
{
  "dashboard": {
    "title": "Advanced Search Performance",
    "panels": [
      {
        "title": "Search Response Times",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, chatwoot_search_duration_seconds)"
          }
        ]
      },
      {
        "title": "Search Volume",
        "type": "graph", 
        "targets": [
          {
            "expr": "rate(chatwoot_search_requests_total[5m])"
          }
        ]
      }
    ]
  }
}
```

---

## Support

For issues or questions about the Advanced Search system:

1. Check the [troubleshooting section](#troubleshooting)
2. Review slow query logs in Redis
3. Monitor performance metrics
4. Contact the development team with specific error details

**Performance Target**: p95 ≤ 300ms ✅