class AddCachedMessageIdsToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :last_message_id, :bigint
    add_column :conversations, :last_incoming_message_id, :bigint
    add_column :conversations, :last_non_activity_message_id, :bigint

    add_index :conversations, :last_message_id
    add_index :conversations, :last_incoming_message_id
    add_index :conversations, :last_non_activity_message_id
  end
end
