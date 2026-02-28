class CreateCaptainWorkflowExecutions < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_workflow_executions do |t|
      t.references :workflow, null: false
      t.references :account, null: false
      t.references :conversation
      t.references :contact
      t.integer :status, default: 0, null: false
      t.datetime :started_at
      t.datetime :completed_at
      t.text :error_message
      t.jsonb :execution_log, default: []

      t.timestamps
    end
  end
end
