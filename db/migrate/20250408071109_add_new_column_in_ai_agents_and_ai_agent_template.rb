class AddNewColumnInAiAgentsAndAiAgentTemplate < ActiveRecord::Migration[7.0]
  def change
    add_column :ai_agents, :chat_flow_id, :string, null: true
    add_column :ai_agent_templates, :template, :jsonb, default: {}, null: false
  end
end
