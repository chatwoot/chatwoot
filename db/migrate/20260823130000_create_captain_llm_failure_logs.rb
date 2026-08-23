class CreateCaptainLlmFailureLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :captain_llm_failure_logs do |t|
      t.string :source, null: false
      t.text :error_message, null: false
      t.string :error_class
      t.integer :error_code
      t.string :provider
      t.string :model
      t.string :endpoint
      t.bigint :account_id
      t.bigint :assistant_id
      t.bigint :conversation_id
      t.jsonb :request_messages
      t.timestamps
    end

    add_index :captain_llm_failure_logs, [:source, :created_at]
    add_index :captain_llm_failure_logs, [:error_code, :created_at]
    add_index :captain_llm_failure_logs, [:account_id, :created_at]
  end
end
