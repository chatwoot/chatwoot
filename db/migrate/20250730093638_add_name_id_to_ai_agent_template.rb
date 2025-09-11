class AddNameIdToAiAgentTemplate < ActiveRecord::Migration[7.0]
  def change
    add_column :ai_agent_templates, :name_id, :string, null: false, default: ''
  end
end
