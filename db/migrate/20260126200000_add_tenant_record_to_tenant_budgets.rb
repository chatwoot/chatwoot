# frozen_string_literal: true

# Adds polymorphic tenant_record association to tenant_budgets table
# This allows the LLMTenant DSL to reference budgets via the model association
class AddTenantRecordToTenantBudgets < ActiveRecord::Migration[7.0]
  def change
    add_reference :ruby_llm_agents_tenant_budgets, :tenant_record, polymorphic: true, index: { name: 'idx_tenant_budgets_on_tenant_record' }
  end
end
