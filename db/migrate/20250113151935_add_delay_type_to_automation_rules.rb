class AddDelayTypeToAutomationRules < ActiveRecord::Migration[7.0]
  def change
    add_column :automation_rules, :delay_type, :string
  end
end
