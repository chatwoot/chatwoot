class IndexMessagesOnClientMessageId < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_messages_on_conversation_id_and_client_message_id'.freeze

  def up
    index = connection.indexes(:messages).find { |definition| definition.name == INDEX_NAME }
    return if index&.valid?

    # An interrupted concurrent build leaves an invalid index behind.
    remove_index :messages, name: INDEX_NAME, algorithm: :concurrently if index
    add_index :messages, [:conversation_id, :client_message_id],
              unique: true, where: 'client_message_id IS NOT NULL',
              name: INDEX_NAME, algorithm: :concurrently
  end

  def down
    remove_index :messages, name: INDEX_NAME, algorithm: :concurrently, if_exists: true
  end
end
