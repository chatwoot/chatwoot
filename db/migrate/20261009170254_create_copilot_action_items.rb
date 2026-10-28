class CreateCopilotActionItems < ActiveRecord::Migration[7.2]
  def change
    create_table :copilot_action_items do |t|
      # The unique index on [copilot_run_id, record_id] serves lookups by run.
      t.references :copilot_run, null: false, index: false
      t.bigint :record_id, null: false
      t.string :status, null: false
      t.string :error
      t.integer :attempts, null: false, default: 0
      t.timestamps
    end
    add_index :copilot_action_items, [:copilot_run_id, :record_id], unique: true
    # Captain::Copilot::RecoverRunsJob expires approvals whose expiry job was lost.
    add_index :copilot_runs, :status, where: "status = 'awaiting_approval'", name: 'index_copilot_runs_awaiting_approval'
  end
end
