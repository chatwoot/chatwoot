class AddStatusUpdatedAtIndexToAutomationRulePendingExecutions < ActiveRecord::Migration[7.0]
  def change
    # Stale reclaim, the abandoned-row alarm and the terminal purge all filter on status + updated_at;
    # the (status, due_at) index does not serve them, and terminal rows linger for 30 days.
    add_index :automation_rule_pending_executions, [:status, :updated_at],
              name: 'index_automation_pending_executions_on_status_and_updated_at'
  end
end
