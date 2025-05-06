class AddColumnStoreConfigInAiAgentTemplates < ActiveRecord::Migration[7.0]
  def change
    add_column :ai_agent_templates, :store_config, :jsonb, default: {}, null: false
  end
end
