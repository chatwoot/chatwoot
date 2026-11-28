class AddOnlyDuringBusinessHoursToAutomationRules < ActiveRecord::Migration[8.0]
  def change
    add_column :automation_rules, :only_during_business_hours, :boolean, default: false, null: false
  end
end
