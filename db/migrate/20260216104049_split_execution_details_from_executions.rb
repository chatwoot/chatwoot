# frozen_string_literal: true

# Idempotent migration to split large payload columns from executions to execution_details.
#
# Handles all upgrade scenarios:
# - execution_details table doesn't exist: creates it and migrates data
# - execution_details table exists but old columns remain on executions: migrates data and removes columns
# - already clean: no-ops safely
class SplitExecutionDetailsFromExecutions < ActiveRecord::Migration[7.1]
  # Columns that belong on execution_details, not executions
  DETAIL_COLUMNS = %i[
    error_message system_prompt user_prompt response messages_summary
    tool_calls attempts fallback_chain parameters routed_to
    classification_result cached_at cache_creation_tokens
  ].freeze

  # Niche columns moved to metadata JSON
  NICHE_COLUMNS = %i[
    span_id response_cache_key time_to_first_token_ms
    retryable rate_limited fallback_reason
  ].freeze

  # Polymorphic tenant columns removed from executions (access via Tenant model)
  TENANT_RECORD_COLUMNS = %i[tenant_record_type tenant_record_id].freeze

  def up
    create_details_table_if_needed
    backfill_and_remove_old_columns
    remove_niche_columns
    remove_tenant_record_columns
    ensure_required_columns
    cleanup_indexes
  end

  def down
    raise ActiveRecord::IrreversibleMigration,
          'This migration cannot be reversed. Use rails db:schema:load to restore.'
  end

  private

  def create_details_table_if_needed
    return if table_exists?(:ruby_llm_agents_execution_details)

    create_table :ruby_llm_agents_execution_details do |t|
      t.references :execution, null: false,
                               foreign_key: { to_table: :ruby_llm_agents_executions, on_delete: :cascade },
                               index: { unique: true }

      t.text     :error_message
      t.text     :system_prompt
      t.text     :user_prompt
      t.json     :response,             default: {}
      t.json     :messages_summary,     default: {}, null: false
      t.json     :tool_calls,           default: [], null: false
      t.json     :attempts,             default: [], null: false
      t.json     :fallback_chain
      t.json     :parameters,           default: {}, null: false
      t.string   :routed_to
      t.json     :classification_result
      t.datetime :cached_at
      t.integer  :cache_creation_tokens, default: 0

      t.timestamps
    end
  end

  def backfill_and_remove_old_columns
    # Only proceed if detail columns still exist on executions
    columns_present = DETAIL_COLUMNS.select { |col| column_exists?(:ruby_llm_agents_executions, col) }
    return if columns_present.empty?

    # Backfill data from executions to execution_details
    say_with_time 'Backfilling execution_details from executions' do
      backfill_execution_details(columns_present)
    end

    # Remove old columns from executions
    columns_present.each do |col|
      remove_column :ruby_llm_agents_executions, col
    end
  end

  def backfill_execution_details(columns_present)
    batch_size = 1000
    count = 0

    # Build WHERE clause to only copy rows that have data
    has_data_conditions = columns_present.map { |col| "e.#{col} IS NOT NULL" }.join(' OR ')

    loop do
      ids = exec_query(<<~SQL).rows.flatten
        SELECT e.id FROM ruby_llm_agents_executions e
        LEFT JOIN ruby_llm_agents_execution_details d ON d.execution_id = e.id
        WHERE d.id IS NULL AND (#{has_data_conditions})
        ORDER BY e.id
        LIMIT #{batch_size}
      SQL

      break if ids.empty?

      # Build dynamic column lists based on what actually exists
      detail_cols = %w[execution_id created_at updated_at] + columns_present.map(&:to_s)
      select_exprs = %w[id created_at updated_at] + columns_present.map do |col|
        case col
        when :messages_summary then "COALESCE(messages_summary, '{}')"
        when :tool_calls then "COALESCE(tool_calls, '[]')"
        when :attempts then "COALESCE(attempts, '[]')"
        when :parameters then "COALESCE(parameters, '{}')"
        else col.to_s
        end
      end

      execute <<~SQL
        INSERT INTO ruby_llm_agents_execution_details (#{detail_cols.join(', ')})
        SELECT #{select_exprs.join(', ')}
        FROM ruby_llm_agents_executions
        WHERE id IN (#{ids.join(',')})
      SQL

      count += ids.size
    end

    count
  end

  def remove_niche_columns
    NICHE_COLUMNS.each do |col|
      remove_column :ruby_llm_agents_executions, col if column_exists?(:ruby_llm_agents_executions, col)
    end
  end

  def remove_tenant_record_columns
    remove_index :ruby_llm_agents_executions, column: TENANT_RECORD_COLUMNS,
                                              name: 'index_executions_on_tenant_record', if_exists: true

    TENANT_RECORD_COLUMNS.each do |col|
      remove_column :ruby_llm_agents_executions, col if column_exists?(:ruby_llm_agents_executions, col)
    end
  end

  def ensure_required_columns
    unless column_exists?(:ruby_llm_agents_executions, :execution_type)
      add_column :ruby_llm_agents_executions, :execution_type, :string, null: false, default: 'chat'
    end
    add_column :ruby_llm_agents_executions, :chosen_model_id, :string unless column_exists?(:ruby_llm_agents_executions, :chosen_model_id)
    unless column_exists?(:ruby_llm_agents_executions, :messages_count)
      add_column :ruby_llm_agents_executions, :messages_count, :integer, default: 0, null: false
    end
    unless column_exists?(:ruby_llm_agents_executions, :attempts_count)
      add_column :ruby_llm_agents_executions, :attempts_count, :integer, default: 1, null: false
    end
    unless column_exists?(:ruby_llm_agents_executions, :tool_calls_count)
      add_column :ruby_llm_agents_executions, :tool_calls_count, :integer, default: 0, null: false
    end
    add_column :ruby_llm_agents_executions, :streaming, :boolean, default: false unless column_exists?(:ruby_llm_agents_executions, :streaming)
    add_column :ruby_llm_agents_executions, :finish_reason, :string unless column_exists?(:ruby_llm_agents_executions, :finish_reason)
    add_column :ruby_llm_agents_executions, :cache_hit, :boolean, default: false unless column_exists?(:ruby_llm_agents_executions, :cache_hit)
    unless column_exists?(:ruby_llm_agents_executions, :trace_id)
      add_column :ruby_llm_agents_executions, :trace_id, :string
      add_index :ruby_llm_agents_executions, :trace_id
    end
    unless column_exists?(:ruby_llm_agents_executions, :request_id)
      add_column :ruby_llm_agents_executions, :request_id, :string
      add_index :ruby_llm_agents_executions, :request_id
    end
    unless column_exists?(:ruby_llm_agents_executions, :parent_execution_id)
      add_column :ruby_llm_agents_executions, :parent_execution_id, :bigint
      add_index :ruby_llm_agents_executions, :parent_execution_id
      add_foreign_key :ruby_llm_agents_executions, :ruby_llm_agents_executions,
                      column: :parent_execution_id, on_delete: :nullify
    end
    unless column_exists?(:ruby_llm_agents_executions, :root_execution_id)
      add_column :ruby_llm_agents_executions, :root_execution_id, :bigint
      add_index :ruby_llm_agents_executions, :root_execution_id
      add_foreign_key :ruby_llm_agents_executions, :ruby_llm_agents_executions,
                      column: :root_execution_id, on_delete: :nullify
    end
    add_column :ruby_llm_agents_executions, :tenant_id, :string unless column_exists?(:ruby_llm_agents_executions, :tenant_id)
    return if column_exists?(:ruby_llm_agents_executions, :cached_tokens)

    add_column :ruby_llm_agents_executions, :cached_tokens, :integer, default: 0
  end

  def cleanup_indexes
    # Remove single-column indexes that are redundant with composite ones
    %i[duration_ms total_cost messages_count attempts_count tool_calls_count
       chosen_model_id execution_type response_cache_key agent_type tenant_id].each do |col|
      remove_index :ruby_llm_agents_executions, col, if_exists: true
    end

    # Ensure composite tenant indexes exist
    add_index :ruby_llm_agents_executions, [:tenant_id, :created_at] unless index_exists?(:ruby_llm_agents_executions, [:tenant_id, :created_at])
    add_index :ruby_llm_agents_executions, [:tenant_id, :status] unless index_exists?(:ruby_llm_agents_executions, [:tenant_id, :status])

    # Remove workflow indexes (feature removed)
    remove_index :ruby_llm_agents_executions, [:workflow_id, :workflow_step], if_exists: true
    remove_index :ruby_llm_agents_executions, :workflow_id, if_exists: true
    remove_index :ruby_llm_agents_executions, :workflow_type, if_exists: true

    # Remove workflow columns if present
    %i[workflow_id workflow_type workflow_step].each do |col|
      remove_column :ruby_llm_agents_executions, col if column_exists?(:ruby_llm_agents_executions, col)
    end

    # Remove agent_version if present
    return unless column_exists?(:ruby_llm_agents_executions, :agent_version)

    remove_index :ruby_llm_agents_executions, [:agent_type, :agent_version], if_exists: true
    remove_column :ruby_llm_agents_executions, :agent_version
  end
end
