class AddIndexToConversationsOnSnoozedUntil < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :conversations, :snoozed_until,
              where: 'status = 3 AND snoozed_until IS NOT NULL',
              name: 'index_conversations_on_snoozed_until_partial',
              algorithm: :concurrently
  end
end
