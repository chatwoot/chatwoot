class AddDisplayIdToConversations < ActiveRecord::Migration[5.0]
  def change
    add_column :conversations, :display_id, :integer
    add_index :conversations, [:account_id, :display_id]
  end
end
