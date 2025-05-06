class AddColumnFlowDataToAiAgents < ActiveRecord::Migration[7.0]
  def change
    add_column :ai_agents, :flow_data, :jsonb, default: {}, null: false
  end
end
