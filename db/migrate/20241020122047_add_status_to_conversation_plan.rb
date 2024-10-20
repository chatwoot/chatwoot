class AddStatusToConversationPlan < ActiveRecord::Migration[7.0]
  def change
    add_column :conversation_plans, :status, :integer, null: false, default: 0
    add_column :conversation_plans, :replied, :boolean, null: false, default: false
  end
end
