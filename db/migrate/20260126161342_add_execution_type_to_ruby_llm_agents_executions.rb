# frozen_string_literal: true

class AddExecutionTypeToRubyLLMAgentsExecutions < ActiveRecord::Migration[7.1]
  def change
    add_column :ruby_llm_agents_executions, :execution_type, :string, default: 'chat'
    add_index :ruby_llm_agents_executions, :execution_type
  end
end
