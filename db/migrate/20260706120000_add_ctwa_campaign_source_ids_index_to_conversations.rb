class AddCtwaCampaignSourceIdsIndexToConversations < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  # The `campaign_source_ids` mirror (jsonb array of source ids) is filtered as text via
  # `additional_attributes ->> 'campaign_source_ids' ILIKE '%"<id>"%'` by both the
  # Conversations filter and the Kanban campaign filter. Only GIN + gin_trgm_ops can serve
  # a double-wildcard ILIKE (pg_trgm is already enabled); the expression is NULL for the
  # vast majority of conversations, so the index stays tiny.
  def change
    add_index :conversations,
              "((additional_attributes ->> 'campaign_source_ids')) gin_trgm_ops",
              name: 'idx_conversations_campaign_source_ids_trgm',
              using: :gin,
              algorithm: :concurrently,
              if_not_exists: true
  end
end
