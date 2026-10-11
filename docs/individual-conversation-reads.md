# Individual conversation reads

The `individual_conversation_reads` account feature makes reading and marking unread personal to the signed-in user. The same user's sessions share one receipt. Reading as an administrator does not clear another agent's unread conversation, sidebar counts, saved filters, or unread sorting.

Receipts contain account, conversation, user, and last-seen time. They do not subscribe the reader as a conversation participant or change access permissions. External contact read state continues to use the existing contact fields. WebSocket conversation and message payloads are personalized for their recipients, while contacts keep their existing payload.

## Rollout

1. Back up the database and apply `CreateConversationReadStates`. The feature defaults to disabled.
2. Deploy the same application image to the web service and both workers before enabling the feature. An old worker would still broadcast shared unread state.
3. Preview the account:

   ```sh
   ACCOUNT_ID=<account-id> bundle exec rails runner script/enable_individual_conversation_reads.rb
   ```

4. Add `APPLY=true` to enable it. The command atomically snapshots the current shared marker into `read_baseline_at` and enables the account feature. Run this command instead of directly toggling the feature. Repeating it preserves existing personal receipts.
5. Refresh dashboard clients to load the new read-state event handler. Verify two users and two sessions of one user: open a conversation, mark unread, receive a new customer message, and compare conversation, inbox, label, team and saved-filter counts.

The snapshot preserves the existing read/unread state for older conversations. It cannot reconstruct which people read messages before activation. Conversations created after activation start without a shared baseline; each user records their own reads.

## Rollback

Disable `individual_conversation_reads` on the account to restore shared read behavior. Keep the receipts and baseline when investigating or temporarily rolling back. Re-enabling through the command preserves saved receipts. Existing assignment policies, working hours, capacity limits, logout settings, and integrations are independent of this feature.
