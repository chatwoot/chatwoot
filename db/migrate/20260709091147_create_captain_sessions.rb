class CreateCaptainSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :captain_sessions do |t|
      t.integer :session_type, null: false
      t.bigint :subject_id, null: false
      t.bigint :result_id
      t.references :account, null: false, index: true
      t.references :assistant, null: false, index: true
      t.references :user, index: true
      t.string :llm_model
      t.float :credits_consumed
      t.jsonb :faq_ids, default: []
      t.jsonb :document_ids, default: []
      t.jsonb :scenario_ids, default: []
      t.jsonb :run_context, default: {}

      t.timestamps
    end

    add_index :captain_sessions, [:session_type, :subject_id]
    add_index :captain_sessions, [:session_type, :result_id]
    add_index :captain_sessions, [:account_id, :session_type, :created_at]
  end
end
