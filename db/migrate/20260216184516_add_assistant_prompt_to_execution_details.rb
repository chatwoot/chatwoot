# frozen_string_literal: true

class AddAssistantPromptToExecutionDetails < ActiveRecord::Migration[7.1]
  def change
    return if column_exists?(:ruby_llm_agents_execution_details, :assistant_prompt)

    add_column :ruby_llm_agents_execution_details, :assistant_prompt, :text
  end
end
