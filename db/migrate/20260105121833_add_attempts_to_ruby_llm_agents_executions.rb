# frozen_string_literal: true

# Migration to add retry/fallback attempt tracking to executions
#
# This migration adds columns for storing attempt details when using
# reliability features (retries, fallbacks, circuit breakers).
#
# Run with: rails db:migrate
class AddAttemptsToRubyLLMAgentsExecutions < ActiveRecord::Migration[7.1]
  def change
    # Add attempts JSON array for storing per-attempt details
    add_column :ruby_llm_agents_executions, :attempts, :json, null: false, default: []

    # Add counter for quick access to attempt count
    add_column :ruby_llm_agents_executions, :attempts_count, :integer, null: false, default: 0

    # Add chosen model (the model that successfully completed the request)
    add_column :ruby_llm_agents_executions, :chosen_model_id, :string

    # Add fallback chain (list of models that were configured to try)
    add_column :ruby_llm_agents_executions, :fallback_chain, :json, null: false, default: []

    # Add indexes for common queries
    add_index :ruby_llm_agents_executions, :attempts_count
    add_index :ruby_llm_agents_executions, :chosen_model_id
  end
end
