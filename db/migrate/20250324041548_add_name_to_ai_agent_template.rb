class AddNameToAiAgentTemplate < ActiveRecord::Migration[7.0]
  def change
    add_column :ai_agent_templates, :name, :string
  end
end
