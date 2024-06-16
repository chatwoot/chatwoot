class AddCountToConversation < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :assignee_unread_count, :integer, null: false, default: 0
    add_column :conversations, :agent_unread_count, :integer, null: false, default: 0
  end
end
