class CreateAiAgentFollowups < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_agent_followups do |t|
      t.references :ai_agent, null: false, foreign_key: true
      t.text :prompts, null: false
      t.integer :delay, default: 5
      t.boolean :send_as_exact_message, default: false, null: false
      t.boolean :handoff_to_agent_after_sending, default: false, null: false
      t.timestamps
    end
  end
end
