# frozen_string_literal: true

# Migration to rename tenant_budgets table to tenants
#
# This migration is for users upgrading from an older version of the gem
# where the table was called 'ruby_llm_agents_tenant_budgets'.
#
# If you're doing a fresh install, use the create_tenants_migration instead.
#
# Run with: rails db:migrate
class RenameTenantBudgetsToTenants < ActiveRecord::Migration[7.1]
  def change
    # Rename the table
    rename_table :ruby_llm_agents_tenant_budgets, :ruby_llm_agents_tenants

    # Add new columns for Tenant model
    add_column :ruby_llm_agents_tenants, :active, :boolean, default: true
    add_column :ruby_llm_agents_tenants, :metadata, :json, null: false, default: {}

    # Add index for active status
    add_index :ruby_llm_agents_tenants, :active

    # Rename indexes to match new table name
    # Note: Some databases handle this automatically when renaming tables
    # If you get an error about missing indexes, you may need to adjust this

    # The polymorphic index needs to be renamed if it exists
    return unless index_exists?(:ruby_llm_agents_tenants, [:tenant_record_type, :tenant_record_id], name: 'index_tenant_budgets_on_tenant_record')

    rename_index :ruby_llm_agents_tenants,
                 'index_tenant_budgets_on_tenant_record',
                 'index_tenants_on_tenant_record'
  end
end
