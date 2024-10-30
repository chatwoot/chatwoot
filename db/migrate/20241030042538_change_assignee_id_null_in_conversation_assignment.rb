class ChangeAssigneeIdNullInConversationAssignment < ActiveRecord::Migration[7.0]
  def change
    change_column_null :conversation_assignments, :assignee_id, true
  end
end
