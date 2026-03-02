# frozen_string_literal: true

class CreateWorkflowRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :workflow_runs do |t|
      t.references :ai_agent, null: false, foreign_key: { to_table: :ai_agents }, index: false
      t.references :conversation, null: false, foreign_key: true, index: true

      t.integer :status, null: false, default: 0 # enum: running, waiting, completed, failed, handed_off
      t.string :current_node_id
      t.jsonb :variables, default: {}
      t.jsonb :messages, default: []
      t.jsonb :execution_log, default: []

      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :workflow_runs, [:ai_agent_id, :status]
  end
end
