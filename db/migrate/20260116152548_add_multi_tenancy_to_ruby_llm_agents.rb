# frozen_string_literal: true

# Adds multi-tenancy support to ruby_llm-agents gem
# This enables per-account budget tracking and scoped analytics
class AddMultiTenancyToRubyLLMAgents < ActiveRecord::Migration[7.0]
  def change
    # Add tenant_id to executions table for per-account tracking
    add_column :ruby_llm_agents_executions, :tenant_id, :string
    add_index :ruby_llm_agents_executions, :tenant_id
    add_index :ruby_llm_agents_executions, [:tenant_id, :agent_type]
    add_index :ruby_llm_agents_executions, [:tenant_id, :created_at]

    # Create tenant budgets table for per-account budget limits
    create_table :ruby_llm_agents_tenant_budgets do |t|
      t.string :tenant_id, null: false
      t.decimal :daily_limit, precision: 12, scale: 6
      t.decimal :monthly_limit, precision: 12, scale: 6
      t.jsonb :per_agent_daily, default: {}
      t.jsonb :per_agent_monthly, default: {}
      t.string :enforcement, default: 'soft' # none, soft, hard

      t.timestamps
    end

    add_index :ruby_llm_agents_tenant_budgets, :tenant_id, unique: true
  end
end
