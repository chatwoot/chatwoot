class AddLastChatMessageAtToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :last_chat_message_at, :datetime
    add_index :conversations, :last_chat_message_at
  end
end
