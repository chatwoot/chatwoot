# Inbox Conversation Migration

This document describes how to use the inbox conversation migration feature to move conversations, messages, attachments, and contacts from one WhatsApp-like inbox to another.

## Overview

The migration feature allows you to:
- Move all conversations from a source inbox to a destination inbox
- Preserve all messages, attachments, and media files
- Merge contacts that have the same WhatsApp identity in both inboxes
- Track migration progress in real-time

## Supported Inbox Types

Migration is only available for WhatsApp-like inboxes:
- **Evolution API inboxes** (Channel::Api with evolution_instance_name)
- **WhatsApp Cloud inboxes** (Channel::Whatsapp with whatsapp_cloud provider)
- **360Dialog WhatsApp inboxes** (Channel::Whatsapp with default provider)
- **Twilio WhatsApp inboxes** (Channel::TwilioSms with medium: whatsapp)

## How to Use

### Via UI

1. Navigate to **Settings → Inboxes → [Your WhatsApp Inbox] → Migration**
2. Select a destination inbox from the dropdown
3. Review the migration preview showing:
   - Number of conversations to migrate
   - Number of messages
   - Number of attachments
   - Number of contacts
   - Any contacts that will be merged (same WhatsApp identity in both inboxes)
4. Click **Start Migration**
5. Type `MIGRATE` in the confirmation modal to confirm
6. Monitor progress on the status panel

### Via Rails Console (Production)

For large migrations or troubleshooting, you can use the Rails console:

```ruby
# Create a migration
migration = InboxMigration.create!(
  account_id: 1,
  source_inbox_id: 4,
  destination_inbox_id: 10,
  user_id: 1
)

# Enqueue the migration job
InboxMigrations::PerformJob.perform_later(migration.id)

# Check migration status
migration.reload
puts "Status: #{migration.status}"
puts "Progress: #{migration.progress_percentage}%"
puts "Conversations: #{migration.conversations_moved}/#{migration.conversations_count}"
puts "Messages: #{migration.messages_moved}/#{migration.messages_count}"
```

## Migration Process

The migration runs in the background and performs these steps:

1. **Validation**: Checks that both inboxes are WhatsApp-like and belong to the same account
2. **Contact Merge Mapping**: Identifies contacts with the same `source_id` (WhatsApp phone number) in both inboxes
3. **Contact Inbox Migration**: Moves `contact_inboxes` records or merges them into destination
4. **Conversation Migration**: Updates `inbox_id` on conversations and remaps contact references if merged
5. **Message Migration**: Updates `inbox_id` on all messages
6. **Cleanup**: Removes orphaned `contact_inboxes` from source inbox

## Monitoring

### Check Migration Status

```ruby
# Find active migrations
InboxMigration.active

# Find migrations for a specific inbox
Inbox.find(4).inbox_migrations_as_source.recent

# Get detailed status
migration = InboxMigration.find(123)
puts migration.attributes.slice(
  'status', 'conversations_count', 'conversations_moved',
  'messages_count', 'messages_moved', 'error_message'
)
```

### View Logs

Migration logs are written to Rails logger with prefix `[InboxMigration {id}]`:

```bash
# In production
docker logs chatwoot 2>&1 | grep "InboxMigration"
```

## Troubleshooting

### Migration Failed

If a migration fails:

1. Check the error message in the UI or via console:
   ```ruby
   migration = InboxMigration.find(123)
   puts migration.error_message
   puts migration.error_backtrace
   ```

2. Common issues:
   - **Lock acquisition failed**: Another migration is running on the same source inbox
   - **Validation errors**: Inboxes are not WhatsApp-like or not in the same account
   - **Database constraint violations**: Usually related to unique indexes on `contact_inboxes`

3. To retry, create a new migration (old failed migrations are preserved for audit)

### Partial Migration

If a migration fails partway through:
- Some data may have already been moved
- Check conversation counts in both inboxes
- The migration is designed to be idempotent - creating a new migration will continue from where it left off (already-moved records will be skipped)

### Rolling Back

There is no automatic rollback. To reverse a migration:

1. Create a new migration from destination → source
2. Or manually update records:
   ```ruby
   # WARNING: Only use if you understand the implications
   Conversation.where(inbox_id: destination_id).update_all(inbox_id: source_id)
   Message.where(inbox_id: destination_id).update_all(inbox_id: source_id)
   ContactInbox.where(inbox_id: destination_id).update_all(inbox_id: source_id)
   ```

## Database Schema

The `inbox_migrations` table tracks all migrations:

| Column | Description |
|--------|-------------|
| `account_id` | Account that owns both inboxes |
| `source_inbox_id` | Inbox to migrate FROM |
| `destination_inbox_id` | Inbox to migrate TO |
| `user_id` | User who initiated the migration |
| `status` | queued, running, completed, failed, cancelled |
| `conversations_count/moved` | Progress tracking |
| `messages_count/moved` | Progress tracking |
| `attachments_count/moved` | Progress tracking |
| `contact_inboxes_count/moved` | Progress tracking |
| `contacts_merged` | Number of contacts that were merged |
| `error_message` | Error details if failed |
| `started_at` | When migration started |
| `completed_at` | When migration finished |

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/accounts/:account_id/inboxes/:inbox_id/migrations` | List migrations |
| GET | `/api/v1/accounts/:account_id/inboxes/:inbox_id/migrations/:id` | Get migration status |
| POST | `/api/v1/accounts/:account_id/inboxes/:inbox_id/migrations` | Start new migration |
| POST | `/api/v1/accounts/:account_id/inboxes/:inbox_id/migrations/:id/cancel` | Cancel queued migration |
| GET | `/api/v1/accounts/:account_id/inboxes/:inbox_id/migrations/preview` | Get migration preview |
| GET | `/api/v1/accounts/:account_id/inboxes/:inbox_id/migrations/eligible_destinations` | List eligible destination inboxes |

## Performance Considerations

- Migrations process data in batches of 500 records to avoid long database locks
- Large migrations (10,000+ conversations) may take several minutes
- Migrations run in the `low` Sidekiq queue to avoid impacting regular operations
- Only one migration can run per source inbox at a time (advisory lock)

## Security

- Only administrators can initiate migrations
- Migrations are scoped to the current account
- All migrations are logged for audit purposes


