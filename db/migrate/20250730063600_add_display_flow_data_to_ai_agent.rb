class AddDisplayFlowDataToAiAgent < ActiveRecord::Migration[7.0]
  def change
    add_column :ai_agents, :display_flow_data, :jsonb, default: {}
  end
end
