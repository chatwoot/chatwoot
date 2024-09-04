class AddConversationAssignmentToAccount < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :conversation_assignment, :integer, null: false, default: 0
  end
end
