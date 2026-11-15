class AddMonitorIndexToAutomationRules < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def up
    remove_foreign_key :automation_rules, column: :monitor_id, if_exists: true
    add_index :automation_rules, :monitor_id, algorithm: :concurrently, if_not_exists: true
  end

  def down
    remove_index :automation_rules, :monitor_id, algorithm: :concurrently, if_exists: true
  end
end
