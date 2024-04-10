class AddIndexToConversations < ActiveRecord::Migration[6.0]
  def change
    add_index :conversations, [:status, :account_id]
    add_index :conversations, [:assignee_id, :account_id]
  end
end
