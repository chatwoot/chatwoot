class AddDescriptionToAiAgentTemplate < ActiveRecord::Migration[7.0]
  def change
    add_column :ai_agent_templates, :description, :string, null: true, default: ''
  end
end
