class AddClientMessageIdToMessages < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    # Durable identity supplied by a client so a send that is retried after a lost
    # response resolves to the original message instead of delivering a second one.
    add_column :messages, :client_message_id, :string, limit: 64
    # Fingerprint of the payload the key was accepted for, stored once at creation so
    # later edits to the message cannot make a conflicting reuse look like a replay.
    add_column :messages, :client_message_digest, :string, limit: 64

    add_index :messages, [:conversation_id, :client_message_id],
              unique: true,
              where: 'client_message_id IS NOT NULL',
              name: 'index_messages_on_conversation_id_and_client_message_id',
              algorithm: :concurrently,
              if_not_exists: true
  end
end
