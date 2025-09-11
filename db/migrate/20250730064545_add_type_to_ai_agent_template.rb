class AddTypeToAiAgentTemplate < ActiveRecord::Migration[7.0]
  def change
    add_column :ai_agent_templates, :type, :string, default: 'FLOWISE', null: false
    add_column :ai_agent_templates, :agent_type, :string, default: 'SINGLE_AGENT', null: false
  end
end
