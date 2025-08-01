class AddTemplateTypeAndAgentTypeToAiAgent < ActiveRecord::Migration[7.0]
  def change
    add_column :ai_agents, :template_type, :string, default: 'FLOWISE', null: false
    add_column :ai_agents, :agent_type, :string, default: 'SINGLE_AGENT', null: false
  end
end
