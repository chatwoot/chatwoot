class AddRequestorToConversation < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :requesting_assignee_id, :integer, null: true
  end
end
