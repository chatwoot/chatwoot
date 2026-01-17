# frozen_string_literal: true

class DropAlooConversationContextsTable < ActiveRecord::Migration[7.0]
  def up
    drop_table :aloo_conversation_contexts, if_exists: true
  end

  def down
    create_table :aloo_conversation_contexts do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :aloo_assistant, null: false, foreign_key: { to_table: :aloo_assistants }
      t.jsonb :context_data, default: {}
      t.jsonb :tool_history, default: []
      t.integer :message_count, default: 0
      t.integer :input_tokens, default: 0
      t.integer :output_tokens, default: 0
      t.decimal :total_cost, precision: 10, scale: 6, default: 0
      t.timestamps
    end

    add_index :aloo_conversation_contexts, :conversation_id, unique: true
  end
end
