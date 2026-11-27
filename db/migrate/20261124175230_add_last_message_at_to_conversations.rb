class AddLastMessageAtToConversations < ActiveRecord::Migration[8.0]
  def change
    add_column :conversations, :last_message_at, :datetime
  end
end
