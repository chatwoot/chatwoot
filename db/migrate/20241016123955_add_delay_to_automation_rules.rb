class AddDelayToAutomationRules < ActiveRecord::Migration[7.0]
  def change
    add_column :automation_rules, :delay, :integer
  end
end
