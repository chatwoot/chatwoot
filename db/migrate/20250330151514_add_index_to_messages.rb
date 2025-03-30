class AddIndexToMessages < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    unless index_exists?(:messages, [:account_id, :conversation_id, :created_at],
                         name: 'idx_messages_on_acct_conv_created_at',
                         order: { created_at: :desc })
      add_index :messages, [:account_id, :conversation_id, :created_at],
                name: 'idx_messages_on_acct_conv_created_at',
                order: { created_at: :desc },
                algorithm: :concurrently
    end
  end
end
