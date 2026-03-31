class AddConfigFieldsToAgentBots < ActiveRecord::Migration[7.0]
  def change
    add_column :agent_bots, :assistant_config, :jsonb, default: {}
    add_column :agent_bots, :agent_behavior_config, :jsonb, default: {}
  end
end
