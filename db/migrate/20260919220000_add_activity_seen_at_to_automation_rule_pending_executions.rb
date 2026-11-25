class AddActivitySeenAtToAutomationRulePendingExecutions < ActiveRecord::Migration[7.0]
  def change
    add_column :automation_rule_pending_executions, :activity_seen_at, :datetime
  end
end
