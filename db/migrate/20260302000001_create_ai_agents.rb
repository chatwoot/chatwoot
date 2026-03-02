# frozen_string_literal: true

class CreateAiAgents < ActiveRecord::Migration[7.1]
  def change
    create_table :ai_agents do |t|
      t.references :account, null: false, foreign_key: true, index: true

      t.string :name, null: false
      t.text :description
      t.integer :agent_type, null: false, default: 0 # enum: rag, tool_calling, voice, hybrid
      t.integer :status, null: false, default: 0      # enum: active, paused, archived

      # LLM configuration
      t.string :model, default: 'gpt-4.1-mini'
      t.text :system_prompt
      t.jsonb :llm_config, default: {}    # temperature, max_tokens, top_p, etc.

      # Voice configuration (Phase 4e)
      t.jsonb :voice_config, default: {}  # voice_id, language, speed, interruption_sensitivity

      # Metadata
      t.jsonb :config, default: {}        # any extra feature toggles

      t.timestamps
    end

    add_index :ai_agents, [:account_id, :status]
    add_index :ai_agents, :agent_type
  end
end
