# frozen_string_literal: true

# Migration to add workflow orchestration columns to executions
#
# This migration adds columns for tracking workflow executions (Pipeline,
# Parallel, Router patterns) and linking child executions to their
# parent workflow.
#
# Workflow patterns supported:
# - Pipeline: Sequential execution with data flowing between steps
# - Parallel: Concurrent execution with result aggregation
# - Router: Conditional dispatch based on classification
#
# Run with: rails db:migrate
class AddWorkflowToRubyLLMAgentsExecutions < ActiveRecord::Migration[7.1]
  def change
    # Unique identifier for the workflow execution
    # All steps/branches share the same workflow_id
    add_column :ruby_llm_agents_executions, :workflow_id, :string

    # Type of workflow: "pipeline", "parallel", "router", or nil for regular agents
    add_column :ruby_llm_agents_executions, :workflow_type, :string

    # Name of the step/branch within the workflow
    add_column :ruby_llm_agents_executions, :workflow_step, :string

    # For routers: the route that was selected
    add_column :ruby_llm_agents_executions, :routed_to, :string

    # For routers: classification details (route, method, time)
    add_column :ruby_llm_agents_executions, :classification_result, :json

    # Add indexes for efficient querying
    add_index :ruby_llm_agents_executions, :workflow_id
    add_index :ruby_llm_agents_executions, :workflow_type
    add_index :ruby_llm_agents_executions, [:workflow_id, :workflow_step]
  end
end
