class AddAccountStatusCreatedAtIndexToConversations < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    # Serves account-scoped conversation lists sorted by created_at (e.g. "newest first"),
    # which otherwise fall back to a backward scan of the global created_at index.
    add_index :conversations, [:account_id, :status, :created_at],
              name: 'index_conversations_on_account_id_status_created_at',
              algorithm: :concurrently,
              if_not_exists: true
  end
end
