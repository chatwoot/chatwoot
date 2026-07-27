class AddFailedOutgoingEmailRetryIndexToMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    add_index :messages, [:created_at, :inbox_id],
              name: 'index_messages_on_failed_outgoing_created_inbox',
              where: 'status = 3 AND message_type = 1',
              algorithm: :concurrently,
              if_not_exists: true
  end

  def down
    remove_index :messages,
                 name: 'index_messages_on_failed_outgoing_created_inbox',
                 algorithm: :concurrently,
                 if_exists: true
  end
end
