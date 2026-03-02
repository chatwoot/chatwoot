# frozen_string_literal: true

class AddMissingIndexesToSaasTables < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    # saas_ai_usage_records - add composite index for per-model usage queries
    add_index :saas_ai_usage_records, [:account_id, :model], algorithm: :concurrently,
              if_not_exists: true, name: 'idx_ai_usage_records_on_account_model'

    # saas_ai_usage_records - add index on feature for feature-level aggregation
    add_index :saas_ai_usage_records, :feature, algorithm: :concurrently,
              if_not_exists: true, name: 'idx_ai_usage_records_on_feature'

    # knowledge_documents - add composite index for status + knowledge_base lookups
    add_index :knowledge_documents, [:knowledge_base_id, :status], algorithm: :concurrently,
              if_not_exists: true, name: 'idx_knowledge_docs_on_kb_status'

    # agent_tools - add index on account_id + tool_type for scoped queries
    add_index :agent_tools, [:account_id, :tool_type], algorithm: :concurrently,
              if_not_exists: true, name: 'idx_agent_tools_on_account_tool_type'
  end
end
