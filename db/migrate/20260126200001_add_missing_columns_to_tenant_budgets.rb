# frozen_string_literal: true

# Adds missing columns expected by ruby_llm-agents 1.1.0 TenantBudget model
class AddMissingColumnsToTenantBudgets < ActiveRecord::Migration[7.0]
  def change
    add_column :ruby_llm_agents_tenant_budgets, :name, :string
    add_column :ruby_llm_agents_tenant_budgets, :daily_token_limit, :integer
    add_column :ruby_llm_agents_tenant_budgets, :monthly_token_limit, :integer
    add_column :ruby_llm_agents_tenant_budgets, :daily_execution_limit, :integer
    add_column :ruby_llm_agents_tenant_budgets, :monthly_execution_limit, :integer
    add_column :ruby_llm_agents_tenant_budgets, :inherit_global_defaults, :boolean, default: true
  end
end
