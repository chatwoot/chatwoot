class AddActiveFlagToAutomationRule < ActiveRecord::Migration[6.1]
  def change
    add_column :automation_rules, :active, :boolean, default: true, null: false
  end
end
