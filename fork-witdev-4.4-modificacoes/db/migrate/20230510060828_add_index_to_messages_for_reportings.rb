class AddIndexToMessagesForReportings < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_index :messages, [:conversation_id, :account_id, :message_type, :created_at], name: 'index_messages_on_conversation_account_type_created',
                                                                                      algorithm: :concurrently
  end
end
