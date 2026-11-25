class AddExecutionDelayTriggerToAutomationRules < ActiveRecord::Migration[7.0]
  def change
    add_column :automation_rules, :execution_delay_trigger, :string
  end
end
