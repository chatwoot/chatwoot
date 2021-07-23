class AddIndexToConversations < ActiveRecord::Migration[6.0]
  def change
    add_index :conversations, :status
    add_index :conversations, :snoozed_until
    add_index :conversations, :assignee_id
  end
end
