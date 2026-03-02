# frozen_string_literal: true

class CreateAiAgentInboxes < ActiveRecord::Migration[7.1]
  def change
    create_table :ai_agent_inboxes do |t|
      t.references :ai_agent, null: false, foreign_key: true, index: true
      t.references :inbox, null: false, foreign_key: true, index: true

      t.boolean :auto_reply, default: true  # whether the agent replies automatically
      t.integer :status, null: false, default: 0 # enum: active, paused

      t.timestamps
    end

    add_index :ai_agent_inboxes, [:ai_agent_id, :inbox_id], unique: true
  end
end
