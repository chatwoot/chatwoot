class AddTriggerCountToAutomationRules < ActiveRecord::Migration[7.0]
  def change
    add_column :automation_rules, :trigger_count, :integer
  end
end
