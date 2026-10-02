class CreateCopilotRuns < ActiveRecord::Migration[7.1]
  def change # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    create_table :copilot_runs do |t|
      t.references :account, null: false
      t.references :user, null: false
      t.references :copilot_thread, null: false
      t.references :copilot_message, index: { unique: true }
      t.references :copilot_run_step, index: { unique: true }
      t.references :parent_run
      t.string :kind, null: false
      t.string :status, null: false, default: 'queued'
      t.jsonb :context, null: false, default: {}
      t.jsonb :provider_state, null: false, default: {}
      t.datetime :lease_until
      t.string :lease_token
      t.integer :attempts, null: false, default: 0
      t.string :error
      t.timestamps
    end

    create_table :copilot_run_steps do |t|
      t.references :copilot_run, null: false
      t.string :call_id, null: false
      t.string :name, null: false
      t.string :status, null: false, default: 'queued'
      t.jsonb :arguments, null: false, default: {}
      t.jsonb :result
      t.jsonb :approval, null: false, default: {}
      t.integer :attempts, null: false, default: 0
      t.string :error
      t.timestamps
    end
    add_index :copilot_run_steps, [:copilot_run_id, :call_id], unique: true

    create_table :copilot_review_findings do |t|
      t.references :copilot_run, null: false
      t.bigint :conversation_id, null: false
      t.string :status, null: false
      t.boolean :needs_attention, null: false, default: false
      t.string :category
      t.text :reason
      t.jsonb :evidence_message_ids, null: false, default: []
      t.jsonb :reviewed_message_ids, null: false, default: []
      t.boolean :history_truncated, null: false, default: false
      t.integer :attempts, null: false, default: 0
      t.string :error
      t.timestamps
    end
    add_index :copilot_review_findings, [:copilot_run_id, :conversation_id], unique: true, name: 'index_copilot_findings_on_run_and_conversation'
  end
end
