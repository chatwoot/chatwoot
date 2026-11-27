# Roll out last-message sorting

The conversation list can order by the latest public message once the account’s history has been populated. Both directions put conversations without a public message last. The default is Last activity. The timestamps displayed on conversation cards are tracked separately in [CW-7853](https://linear.app/chatwoot/issue/CW-7853/incorrect-conversation-activity-indicator).

1. Run the Rails migrations and deploy the message and import writers to every web and worker process. The two account-scoped indexes are built concurrently, in separate migrations. Check that both are valid before enabling sorting. A failed concurrent build can leave an invalid index that needs to be removed before retrying its migration.
2. Start with one existing account. From a Rails console, enqueue the job below and ensure a worker consumes the `async_database_migration` queue.

   ```ruby
   account = Account.find(account_id)
   Migration::BackfillConversationLastMessageAtJob.perform_later(account)
   ```

   Each job reads up to 100 conversations and schedules one continuation carrying its last processed ID and the initial upper bound. The completion log names the account and upper bound. Re-running a range is safe while new replies arrive. For a pilot or a paused rollout, pass two conversation database IDs as `perform_later(account, after_id, through_id)`. The lower bound is exclusive and the upper bound inclusive. Start the next range at the completed upper bound.
3. Check samples including private-note-only, imported, recently active, and older conversations. Compare the stored timestamp with the latest public message and check that the sort index is selected for representative queues. Monitor database I/O, replica lag and message-write latency as batches run.

   ```ruby
   conversation = account.conversations.find(conversation_id)
   [conversation.last_message_at, conversation.messages.where(account_id: account.id).chat.maximum(:created_at)]
   ```

4. Enable **Sort conversations by last message** for the verified account in Super Admin, or run `account.enable_features!(:last_message_sort)`. Refresh the dashboard and choose either Last message order. Existing accounts can be rolled out in waves. New accounts use the installation’s account feature defaults.
5. To roll back the sort, disable the same account feature. Agents can continue using Last activity. New public messages continue to maintain the timestamp and its indexes. If web or worker processes revert to a version without the timestamp writer, repeat the reconciliation for affected accounts after redeploying the writer.
