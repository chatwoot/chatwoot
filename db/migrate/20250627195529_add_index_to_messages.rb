class AddIndexToMessages < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    # This index is added as a temporary fix for performance issues in the CSAT
    # responses controller where we query messages with account_id, content_type
    # and created_at. The current implementation (account.message.input_csat.count)
    # times out with millions of messages.
    #
    # TODO: Create a dedicated csat_survey table and add entries when surveys are
    # sent, then query this table instead of the entire messages table for better
    # performance.
    return if index_exists?(
      :messages,
      [:account_id, :content_type, :created_at],
      name: 'idx_messages_account_content_created'
    )

    add_index :messages, [:account_id, :content_type, :created_at],
              name: 'idx_messages_account_content_created', algorithm: :concurrently
  end
end
