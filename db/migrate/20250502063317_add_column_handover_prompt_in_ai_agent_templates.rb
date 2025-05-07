class AddColumnHandoverPromptInAiAgentTemplates < ActiveRecord::Migration[7.0]
  def change
    add_column :ai_agent_templates, :handover_prompt, :text, default: nil
  end
end
