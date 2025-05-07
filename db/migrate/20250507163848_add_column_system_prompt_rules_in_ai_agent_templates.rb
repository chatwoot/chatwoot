class AddColumnSystemPromptRulesInAiAgentTemplates < ActiveRecord::Migration[7.0]
  def change
    add_column :ai_agent_templates, :system_prompt_rules, :text, default: nil
  end
end
