class RenameTypeColumnInAiAgentTemplates < ActiveRecord::Migration[7.0]
  def change
    rename_column :ai_agent_templates, :type, :source_type
  end
end
