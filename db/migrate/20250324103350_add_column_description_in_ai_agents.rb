class AddColumnDescriptionInAiAgents < ActiveRecord::Migration[7.0]
  def change
    add_column :ai_agents, :description, :string, limits: 255, null: true
  end
end
