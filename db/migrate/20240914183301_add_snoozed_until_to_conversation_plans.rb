class AddSnoozedUntilToConversationPlans < ActiveRecord::Migration[7.0]
  def change
    add_column :conversation_plans, :snoozed_until, :datetime, null: true
  end
end
