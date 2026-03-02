# frozen_string_literal: true

class AddWorkflowToAiAgents < ActiveRecord::Migration[7.1]
  def change
    add_column :ai_agents, :workflow, :jsonb, default: nil
  end
end
