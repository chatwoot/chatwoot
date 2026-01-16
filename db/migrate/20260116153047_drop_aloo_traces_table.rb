# frozen_string_literal: true

# Remove Aloo::Trace model - tracing is now handled by ruby_llm-agents gem's Execution model
class DropAlooTracesTable < ActiveRecord::Migration[7.0]
  def up
    drop_table :aloo_traces, if_exists: true
  end

  def down
    create_table :aloo_traces do |t|
      t.references :account, null: false, foreign_key: true
      t.references :aloo_assistant, foreign_key: { to_table: :aloo_assistants }
      t.references :conversation, foreign_key: true
      t.string :trace_type, null: false
      t.string :request_id
      t.boolean :success, default: true
      t.integer :duration_ms
      t.jsonb :input_data, default: {}
      t.jsonb :output_data, default: {}
      t.integer :input_tokens
      t.integer :output_tokens
      t.string :error_message
      t.timestamps
    end

    add_index :aloo_traces, :trace_type
    add_index :aloo_traces, :request_id
    add_index :aloo_traces, :created_at
    add_index :aloo_traces, [:account_id, :trace_type]
  end
end
