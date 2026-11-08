class CreateCopilotRuns < ActiveRecord::Migration[7.2]
  def change
    create_copilot_runs
    create_copilot_tool_calls
    create_copilot_review_findings
    add_recovery_indexes
  end

  private

  def create_copilot_runs
    create_table :copilot_runs do |t|
      t.references :account, null: false
      t.references :user, null: false
      t.references :copilot_thread, null: false
      t.references :copilot_message, index: { unique: true }
      t.references :copilot_tool_call, index: { unique: true }
      t.references :source_run
      t.string :type, null: false
      t.string :status, null: false, default: 'queued'
      t.jsonb :context, null: false, default: {}
      t.jsonb :transcript, null: false, default: {}
      t.decimal :total_cost_usd, precision: 16, scale: 10, null: false, default: 0
      t.boolean :cost_complete, null: false, default: true
      t.datetime :lease_until
      t.string :lease_token
      t.integer :attempts, null: false, default: 0
      t.string :error
      t.timestamps
    end
  end

  def create_copilot_tool_calls
    create_table :copilot_tool_calls do |t|
      # The unique index on [copilot_run_id, call_id] serves lookups by run.
      t.references :copilot_run, null: false, index: false
      t.string :call_id, null: false
      t.string :name, null: false
      t.string :status, null: false, default: 'queued'
      t.jsonb :arguments, null: false, default: {}
      t.jsonb :result
      t.integer :attempts, null: false, default: 0
      t.string :error
      t.timestamps
    end
    add_index :copilot_tool_calls, [:copilot_run_id, :call_id], unique: true
  end

  def create_copilot_review_findings
    create_table :copilot_review_findings do |t|
      # The unique index on [copilot_run_id, conversation_id] serves lookups by run.
      t.references :copilot_run, null: false, index: false
      t.bigint :conversation_id, null: false
      t.string :status, null: false
      t.boolean :matched, null: false, default: false
      t.string :category
      t.text :reason
      t.float :screening_score
      t.jsonb :evidence_message_ids, null: false, default: []
      t.jsonb :reviewed_message_ids, null: false, default: []
      t.boolean :history_truncated, null: false, default: false
      t.integer :attempts, null: false, default: 0
      t.string :error
      t.timestamps
    end
    add_index :copilot_review_findings, [:copilot_run_id, :conversation_id], unique: true, name: 'index_copilot_findings_on_run_and_conversation'
  end

  # Captain::Copilot::RecoverRunsJob checks every account for unfinished runs and running tool calls, a small part of
  # tables that keep growing.
  def add_recovery_indexes
    add_index :copilot_runs, :status, where: "status IN ('queued', 'running')", name: 'index_copilot_runs_claimable'
    add_index :copilot_tool_calls, :status, where: "status = 'running'", name: 'index_copilot_tool_calls_running'
  end
end
