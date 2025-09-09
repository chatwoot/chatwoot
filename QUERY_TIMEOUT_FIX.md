# Query Timeout Fix for ImapMailbox

## Issue Description
The application was experiencing PostgreSQL query timeouts (`ActiveRecord::QueryCanceled: PG::QueryCanceled: ERROR: canceling statement due to statement timeout`) when processing IMAP emails. The error was occurring in the `Imap::ImapMailbox#find_conversation_by_in_reply_to` method at line 45.

### Root Cause
The problematic query was:
```ruby
@inbox.conversations.where("additional_attributes->>'in_reply_to' = ?", in_reply_to).first
```

This query performs a JSONB text extraction (`->>`) on the `additional_attributes` column without any index, causing a full table scan on potentially millions of conversations, leading to query timeouts.

## Solution Implemented

### 1. Database Index Addition
Created migration `20250909000001_add_index_conversations_additional_attributes_in_reply_to.rb` to add a specialized index:

```ruby
add_index :conversations, 
          "((additional_attributes->>'in_reply_to'))", 
          name: 'index_conversations_on_additional_attributes_in_reply_to',
          algorithm: :concurrently,
          where: "additional_attributes->>'in_reply_to' IS NOT NULL"
```

**Key features:**
- **Functional Index**: Indexes the extracted JSONB value directly
- **Concurrent Creation**: Uses `algorithm: :concurrently` to avoid locking during deployment
- **Partial Index**: Only indexes rows where `in_reply_to` is not null, reducing index size
- **Optimized for Queries**: Directly supports the `additional_attributes->>'in_reply_to' = ?` pattern

### 2. Query Optimization
Enhanced both `ImapMailbox` and `SupportMailbox` classes:

#### ImapMailbox Changes
- Added `.limit(1)` to prevent unnecessary full result set loading
- Added error handling for `ActiveRecord::QueryCanceled`
- Added logging for timeout events
- Graceful degradation: returns `nil` on timeout, allowing new conversation creation

#### SupportMailbox Changes
- Applied the same optimizations as ImapMailbox
- Consistent error handling across both mailbox types

### 3. Error Handling Strategy
```ruby
begin
  @inbox.conversations
        .where("additional_attributes->>'in_reply_to' = ?", in_reply_to)
        .limit(1)
        .first
rescue ActiveRecord::QueryCanceled => e
  Rails.logger.error "Query timeout in find_conversation_by_in_reply_to for in_reply_to: #{in_reply_to}, inbox: #{@inbox.id}"
  Rails.logger.error e.message
  # Return nil to allow conversation creation to proceed
  nil
end
```

**Benefits:**
- **Graceful Degradation**: Application continues functioning even if the query times out
- **Monitoring**: Logs timeout events for monitoring and alerting
- **User Experience**: Email processing continues, creating new conversations when needed

### 4. Test Coverage
Added comprehensive test coverage in `spec/mailboxes/imap/imap_mailbox_spec.rb`:
- Test for graceful timeout handling
- Test for proper logging of timeout events
- Verification that new conversations are created when timeouts occur

## Deployment Instructions

### 1. Deploy the Migration
```bash
# Run the migration (uses concurrent index creation)
rails db:migrate

# Verify the index was created
rails db:migrate:status
```

### 2. Monitor the Index Creation
The migration uses `algorithm: :concurrently`, which means:
- **No table locking** during index creation
- **Safe for production** deployment
- **May take time** on large tables (monitor progress in PostgreSQL logs)

### 3. Verify the Fix
After deployment, monitor:
- **Sentry alerts**: Should see a reduction in `ActiveRecord::QueryCanceled` errors
- **Application logs**: Look for successful email processing
- **Query performance**: Monitor PostgreSQL slow query logs

## Performance Impact

### Before Fix
- **Query Type**: Full table scan on conversations table
- **Performance**: O(n) where n = total conversations
- **Timeout Risk**: High on tables with millions of rows

### After Fix
- **Query Type**: Index lookup + limit
- **Performance**: O(log n) with early termination
- **Timeout Risk**: Minimal due to index + error handling

## Monitoring and Alerting

### Key Metrics to Monitor
1. **Query Timeout Logs**: 
   ```
   grep "Query timeout in find_conversation_by_in_reply_to" /path/to/logs/production.log
   ```

2. **Sentry Error Reduction**: 
   - Monitor the `CHATWOOT-8ZM` Sentry issue for reduced occurrences

3. **Database Performance**:
   ```sql
   -- Check index usage
   SELECT schemaname, tablename, indexname, idx_tup_read, idx_tup_fetch 
   FROM pg_stat_user_indexes 
   WHERE indexname = 'index_conversations_on_additional_attributes_in_reply_to';
   ```

### Expected Outcomes
- **Immediate**: Elimination of query timeout errors in ImapMailbox
- **Short-term**: Improved email processing reliability
- **Long-term**: Better scalability for high-volume email processing

## Rollback Plan

If issues arise, the changes can be safely rolled back:

1. **Revert Code Changes**:
   ```bash
   git revert <commit-hash>
   ```

2. **Remove Index** (if necessary):
   ```ruby
   # Create rollback migration if needed
   remove_index :conversations, name: 'index_conversations_on_additional_attributes_in_reply_to'
   ```

## Related Files Modified
- `app/mailboxes/imap/imap_mailbox.rb`
- `app/mailboxes/support_mailbox.rb`
- `db/migrate/20250909000001_add_index_conversations_additional_attributes_in_reply_to.rb`
- `spec/mailboxes/imap/imap_mailbox_spec.rb`

## Additional Recommendations

1. **Consider Similar Patterns**: Audit other JSONB queries in the codebase for similar performance issues
2. **Monitoring**: Set up alerts for query timeout patterns
3. **Index Maintenance**: Monitor index size and performance over time
4. **Query Analysis**: Regularly review slow query logs for optimization opportunities

## Impact Assessment
- **Risk Level**: Low (graceful error handling prevents service disruption)
- **Performance Improvement**: High (eliminates table scans)
- **Deployment Safety**: High (concurrent index creation, backward compatible)
- **User Experience**: Improved (eliminates email processing failures)