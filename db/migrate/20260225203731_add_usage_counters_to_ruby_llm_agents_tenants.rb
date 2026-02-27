# frozen_string_literal: true

# Migration to add usage counter columns to tenants table
#
# These columns enable DB-based budget tracking with atomic SQL increments,
# replacing the previous cache-based counter approach.
#
# Run with: rails db:migrate
class AddUsageCountersToRubyLLMAgentsTenants < ActiveRecord::Migration[7.1]
  def change
    change_table :ruby_llm_agents_tenants, bulk: true do |t|
      # Cost counters
      t.decimal :daily_cost_spent,        precision: 12, scale: 6, default: 0, null: false
      t.decimal :monthly_cost_spent,      precision: 12, scale: 6, default: 0, null: false

      # Token counters
      t.bigint :daily_tokens_used,        default: 0, null: false
      t.bigint :monthly_tokens_used,      default: 0, null: false

      # Execution counters
      t.bigint :daily_executions_count,   default: 0, null: false
      t.bigint :monthly_executions_count, default: 0, null: false

      # Error counters
      t.bigint :daily_error_count,        default: 0, null: false
      t.bigint :monthly_error_count,      default: 0, null: false

      # Last execution metadata
      t.datetime :last_execution_at
      t.string   :last_execution_status

      # Period tracking (for lazy reset)
      t.date :daily_reset_date
      t.date :monthly_reset_date
    end
  end
end
