class AddAiAssigneeTypeToConversations < ActiveRecord::Migration[7.1]
  def change
    add_column :conversations, :ai_assignee_type, :string
  end
end
