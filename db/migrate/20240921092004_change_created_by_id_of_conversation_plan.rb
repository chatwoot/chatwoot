class ChangeCreatedByIdOfConversationPlan < ActiveRecord::Migration[7.0]
  def change
    change_column_null :conversation_plans, :created_by_id, true
  end
end
