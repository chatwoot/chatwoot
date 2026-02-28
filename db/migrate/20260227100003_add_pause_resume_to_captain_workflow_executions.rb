class AddPauseResumeToCaptainWorkflowExecutions < ActiveRecord::Migration[7.1]
  def change
    add_column :captain_workflow_executions, :current_node_id, :string
    add_column :captain_workflow_executions, :context_store, :jsonb, default: {}
  end
end
