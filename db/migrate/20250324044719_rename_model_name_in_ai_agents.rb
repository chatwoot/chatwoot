class RenameModelNameInAiAgents < ActiveRecord::Migration[7.0]
  def change
    rename_column :ai_agents, :model_name, :llm_model
  end
end
