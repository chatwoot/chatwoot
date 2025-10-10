# Unified Template System - Migration Guide

## Overview

This migration system converts existing channel-specific templates to the unified template system. It supports:

1. **WhatsApp Templates** - From `message_templates` JSONB field
2. **Twilio SMS/WhatsApp Templates** - From `content_templates` JSONB field
3. **Apple Messages Templates** - Creates example templates for common use cases
4. **Canned Responses** - Converts to multi-channel templates

## Prerequisites

1. **Backup Database**: Always backup your database before migration
   ```bash
   pg_dump chatwoot_production > backup_$(date +%Y%m%d).sql
   ```

2. **Run Migrations**: Ensure unified template system tables exist
   ```bash
   bundle exec rails db:migrate
   ```

3. **Verify Models**: Check that all models load without errors
   ```bash
   bundle exec rails runner "puts MessageTemplate.count"
   ```

## Migration Commands

### Migrate All Templates

Migrate all templates from all sources in one command:

```bash
bundle exec rake templates:migrate:all
```

This runs migrations in order:
1. WhatsApp Templates
2. Twilio Templates
3. Apple Messages Templates
4. Canned Responses

### Migrate Individual Sources

Migrate specific sources individually:

```bash
# WhatsApp only
bundle exec rake templates:migrate:whatsapp

# Twilio SMS/WhatsApp only
bundle exec rake templates:migrate:twilio

# Apple Messages only
bundle exec rake templates:migrate:apple_messages

# Canned Responses only
bundle exec rake templates:migrate:canned_responses
```

### Validate Migrations

Validate migration results to ensure data integrity:

```bash
# Validate all
bundle exec rake templates:validate

# Validate specific source
bundle exec rake templates:validate:whatsapp
bundle exec rake templates:validate:twilio
bundle exec rake templates:validate:apple_messages
bundle exec rake templates:validate:canned_responses
```

### View Statistics

View migration statistics:

```bash
bundle exec rake templates:stats
```

This shows:
- Templates by migration source
- Templates by channel
- Total counts
- Average blocks per template

### Rollback Migrations

If you need to rollback migrations:

```bash
# Rollback all (requires confirmation)
bundle exec rake templates:rollback:all

# Rollback specific source
bundle exec rake templates:rollback:whatsapp
bundle exec rake templates:rollback:twilio
bundle exec rake templates:rollback:apple_messages
bundle exec rake templates:rollback:canned_responses
```

**Important**: Rollback only deletes migrated templates. Original data in JSONB fields remains untouched.

## Migration Process Details

### WhatsApp Templates

**Source**: `channel_whatsapp.message_templates` JSONB field

**Process**:
1. Extracts WhatsApp template structure (name, components, language, status)
2. Maps WhatsApp categories to unified categories
3. Extracts parameters from `{{1}}`, `{{2}}`, etc. placeholders
4. Creates content blocks from HEADER, BODY, FOOTER, BUTTONS components
5. Builds WhatsApp channel mapping

**Example**:
```json
{
  "name": "order_confirmation",
  "language": "en",
  "status": "APPROVED",
  "category": "MARKETING",
  "components": [
    {
      "type": "BODY",
      "text": "Your order {{1}} has been confirmed!"
    }
  ]
}
```

Becomes:
- **MessageTemplate**: `name: "order_confirmation"`, `category: "marketing"`
- **TemplateContentBlock**: `type: "text"`, `properties: { content: "Your order {{1}} has been confirmed!" }`
- **Parameters**: `{ "param_1": { type: "string", required: true } }`

### Twilio Templates

**Source**: `channel_twilio_sms.content_templates` JSONB field

**Process**:
1. Extracts Twilio Content API structure (types, variables, language)
2. Maps content types to block types (text, media, quick-reply, list-picker)
3. Extracts parameters from variables definition
4. Creates appropriate channel mappings for SMS and WhatsApp
5. Determines supported channels based on content types

**Example**:
```json
{
  "friendly_name": "appointment_reminder",
  "language": "en",
  "types": {
    "twilio/text": {
      "body": "Reminder: Your appointment is tomorrow at {{time}}"
    }
  },
  "variables": {
    "time": {
      "type": "text",
      "required": true
    }
  }
}
```

Becomes:
- **MessageTemplate**: `name: "appointment_reminder"`, `category: "notification"`
- **TemplateContentBlock**: `type: "text"`, `properties: { content: "..." }`
- **Parameters**: `{ "time": { type: "string", required: true } }`

### Apple Messages Templates

**Source**: Creates example templates (no existing data to migrate)

**Process**:
1. Creates 5 example templates per Apple Messages channel:
   - Time Picker (appointment booking)
   - List Picker (product selection)
   - Apple Pay (payment request)
   - Form (information collection)
   - Rich Link (content sharing)
2. Each template includes full parameter definitions
3. Includes Apple Messages-specific channel mappings

**Use Case**:
These example templates serve as:
- Starting points for customization
- Reference implementations
- Testing templates

### Canned Responses

**Source**: `canned_responses` table

**Process**:
1. Extracts short_code and content
2. Parses `{{variable}}` placeholders
3. Infers parameter types from variable names
4. Determines category from content analysis
5. Creates channel mappings for all text-based channels

**Example**:
```sql
short_code: "thanks_reply"
content: "Thank you {{customer_name}} for contacting us!"
```

Becomes:
- **MessageTemplate**: `name: "thanks_reply"`, `category: "support"`
- **TemplateContentBlock**: `type: "text"`, `properties: { content: "Thank you {{customer_name}} for contacting us!" }`
- **Parameters**: `{ "customer_name": { type: "string", required: false, example: "John Doe" } }`
- **Supported Channels**: All text-based channels

## Migration Metadata

Each migrated template includes metadata for tracking:

```json
{
  "migration_source": "whatsapp_migration|twilio_migration|apple_messages_migration|canned_response_migration",
  "migrated_at": "2025-10-10T12:00:00Z",
  "original_id": "template_123",
  "original_data": { ... },
  "migration_version": "1.0"
}
```

This metadata:
- Tracks migration source for rollback
- Preserves original data for reference
- Enables re-migration if needed
- Supports audit trails

## Idempotency

All migration tasks are **idempotent** - you can run them multiple times safely:

- **First run**: Migrates all templates
- **Subsequent runs**: Skips existing templates
- **New templates**: Only migrates newly added templates

This allows:
- Safe re-runs after failures
- Incremental migrations
- Testing without cleanup

## Error Handling

The migration system handles errors gracefully:

### Transaction Rollback

All migrations run in database transactions:
- If any error occurs, entire migration rolls back
- Database remains in consistent state
- No partial migrations

### Individual Template Errors

Individual template failures don't stop migration:
- Error is logged with details
- Migration continues with next template
- Final report shows all errors

### Validation Errors

Validation detects:
- Template count mismatches
- Missing channel mappings
- Missing content blocks
- Rendering failures

## Best Practices

### 1. Test in Development First

```bash
# Development environment
RAILS_ENV=development bundle exec rake templates:migrate:all
RAILS_ENV=development bundle exec rake templates:validate
```

### 2. Migrate in Stages

For large datasets, migrate in stages:

```bash
# Day 1: Migrate and validate WhatsApp
bundle exec rake templates:migrate:whatsapp
bundle exec rake templates:validate:whatsapp

# Day 2: Migrate and validate Twilio
bundle exec rake templates:migrate:twilio
bundle exec rake templates:validate:twilio

# Day 3: Migrate canned responses
bundle exec rake templates:migrate:canned_responses
bundle exec rake templates:validate:canned_responses
```

### 3. Monitor Performance

For large migrations:

```bash
# Enable SQL logging
RAILS_ENV=production LOG_LEVEL=debug bundle exec rake templates:migrate:all

# Monitor database
watch -n 1 'psql chatwoot_production -c "SELECT count(*) FROM message_templates"'
```

### 4. Verify After Migration

```bash
# Check counts
bundle exec rake templates:stats

# Validate all
bundle exec rake templates:validate

# Test template rendering
bundle exec rails console
> template = MessageTemplate.first
> template.content_blocks.first.render_for_channel('whatsapp', {})
```

## Troubleshooting

### Migration Hangs

**Cause**: Large dataset or slow database

**Solution**:
```bash
# Check progress
psql chatwoot_production -c "SELECT migration_source, count(*) FROM message_templates WHERE metadata->>'migration_source' IS NOT NULL GROUP BY migration_source"

# Kill and restart
# Migration is idempotent - safe to restart
```

### Validation Failures

**Cause**: Template count mismatch

**Solution**:
```bash
# Check original counts
bundle exec rails console
> Channel::Whatsapp.sum { |c| c.message_templates&.keys&.count || 0 }
> MessageTemplate.where("metadata->>'migration_source' = 'whatsapp_migration'").count

# Re-run migration (skips existing)
bundle exec rake templates:migrate:whatsapp
```

### Missing Channel Mappings

**Cause**: Channel-specific logic missing

**Solution**:
```bash
# Check which templates need mappings
bundle exec rails console
> MessageTemplate.joins("LEFT JOIN template_channel_mappings ON template_channel_mappings.message_template_id = message_templates.id")
>   .where("template_channel_mappings.id IS NULL")
>   .pluck(:id, :name)

# Manual fix if needed
> template = MessageTemplate.find(123)
> template.channel_mappings.create!(
    channel_type: 'whatsapp',
    content_type: 'text',
    field_mappings: { 'text.body' => '{{content}}' }
  )
```

### Parameter Type Errors

**Cause**: Incorrect parameter type inference

**Solution**:
```bash
# Check parameters
bundle exec rails console
> template = MessageTemplate.find(123)
> template.parameters

# Fix manually
> template.update(parameters: {
    'order_id' => { 'type' => 'string', 'required' => true }
  })
```

## Post-Migration

After successful migration:

### 1. Update Application Code

Update controllers and services to use `MessageTemplate`:

```ruby
# Before: Using canned responses
canned_response = CannedResponse.find_by(short_code: 'thanks')

# After: Using message templates
template = MessageTemplate.find_by(name: 'thanks', account_id: account.id)
```

### 2. Update Frontend

Update UI to show unified templates instead of channel-specific:

```javascript
// Before: Channel-specific endpoints
GET /api/v1/accounts/:id/inboxes/:inbox_id/whatsapp_templates

// After: Unified templates
GET /api/v1/accounts/:id/templates?channel=whatsapp
```

### 3. Deprecate Old Fields

Plan to deprecate old JSONB fields:

```ruby
# Phase 1: Read from both (current state after migration)
# Phase 2: Write only to new system, read from both
# Phase 3: Read only from new system
# Phase 4: Remove old JSONB fields
```

### 4. Monitor Usage

Track template usage:

```ruby
# Enable usage logging
MessageTemplate.find(123).usage_logs.create!(
  account_id: account.id,
  conversation_id: conversation.id,
  sender_type: 'User',
  sender_id: user.id,
  parameters_used: { name: 'John' },
  channel_type: 'whatsapp',
  success: true
)

# Analyze usage
MessageTemplate
  .joins(:usage_logs)
  .group(:name)
  .order('count_all DESC')
  .count
```

## Support

For issues or questions:

1. Check migration logs: `log/templates_migration.log`
2. Run validation: `bundle exec rake templates:validate`
3. Check database: `psql chatwoot_production -c "SELECT * FROM message_templates LIMIT 10"`
4. Review documentation: `/Users/rhaps/LocalGit/chatwoot/docs/UNIFIED_TEMPLATE_SYSTEM_ARCHITECTURE.md`

## Rollback Strategy

If migration causes issues:

### Immediate Rollback

```bash
# Rollback specific source
bundle exec rake templates:rollback:whatsapp

# Original data in JSONB fields is preserved
# Application continues using old system
```

### Gradual Rollback

```bash
# 1. Stop using new templates in application code
# 2. Rollback migrations one by one
# 3. Verify application functionality
# 4. Original data still available
```

### Complete Rollback

```bash
# Nuclear option: Remove all migrated templates
bundle exec rake templates:rollback:all

# Confirm when prompted
# All migrated templates deleted
# Original JSONB data preserved
```

## Next Steps

After successful migration:

1. **Phase 1 Complete**: Templates migrated ✓
2. **Phase 2**: Update controllers and services
3. **Phase 3**: Build template management UI
4. **Phase 4**: Add bot integration APIs
5. **Phase 5**: Deprecate old JSONB fields
6. **Phase 6**: Add advanced features (versioning, A/B testing, analytics)

For implementation details of Phases 2-6, see:
- `/Users/rhaps/LocalGit/chatwoot/docs/UNIFIED_TEMPLATE_SYSTEM_ARCHITECTURE.md`
