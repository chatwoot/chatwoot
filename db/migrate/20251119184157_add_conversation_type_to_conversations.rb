class AddConversationTypeToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :conversation_type, :integer, default: 0, null: false
    add_index :conversations, :conversation_type
  end
end
