class CreateCopilotRuns < ActiveRecord::Migration[7.1]
  def change # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    create_table :copilot_runs do |t|
      t.references :copilot_thread, null: false, foreign_key: { on_delete: :cascade }
      t.references :triggering_message, null: false, foreign_key: { to_table: :copilot_messages, on_delete: :cascade }, index: { unique: true }
      t.references :response_message, foreign_key: { to_table: :copilot_messages, on_delete: :nullify }
      t.string :status, null: false, default: 'queued'
      t.string :reason
      t.jsonb :task_spec, null: false, default: {}
      t.jsonb :datasets, null: false, default: {}
      t.jsonb :checkpoint, null: false, default: {}
      t.jsonb :result_summary, null: false, default: {}
      t.jsonb :budget, null: false, default: {}
      t.integer :claim_generation, null: false, default: 0
      t.datetime :lease_expires_at
      t.datetime :charged_at
      t.datetime :completed_at
      t.timestamps
    end
    add_index :copilot_runs, :copilot_thread_id, unique: true,
                                                 where: "status IN ('queued', 'running', 'needs_clarification')",
                                                 name: 'index_copilot_runs_one_active_thread'
    add_index :copilot_runs, [:status, :lease_expires_at]
    create_table :copilot_run_items do |t|
      t.references :copilot_run, null: false, foreign_key: { on_delete: :cascade }
      t.string :dataset_key, null: false
      t.string :resource_type, null: false
      t.string :resource_id, null: false
      t.integer :position, null: false
      t.references :source_item, foreign_key: { to_table: :copilot_run_items, on_delete: :cascade }
      t.jsonb :captured, null: false, default: {}
      t.string :state, null: false, default: 'captured'
      t.jsonb :result, null: false, default: {}
      t.string :reason
      t.integer :attempts, null: false, default: 0
      t.boolean :supplied, null: false, default: false
      t.timestamps
    end
    add_index :copilot_run_items, [:copilot_run_id, :dataset_key, :resource_type, :resource_id], unique: true,
                                                                                                 name: 'index_copilot_run_items_identity'
    add_reference :copilot_messages, :copilot_run, foreign_key: { on_delete: :nullify }
  end
end
