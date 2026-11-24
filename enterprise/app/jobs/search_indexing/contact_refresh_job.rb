class SearchIndexing::ContactRefreshJob < ApplicationJob
  queue_as :async_database_migration

  def perform(account_id, contact_id, after_id = 0)
    return unless ChatwootApp.advanced_search_allowed?

    ids = ActiveRecord::Base.connected_to(role: :writing) do
      Conversation.where(account_id: account_id, contact_id: contact_id).where(Conversation.arel_table[:id].gt(after_id))
                  .order(:id).limit(SearchIndexing::Conversations::BATCH_SIZE).pluck(:id)
    end
    Conversation.search_index.reindex_queue.push(ids) if ids.any?
    self.class.perform_later(account_id, contact_id, ids.last) if ids.size == SearchIndexing::Conversations::BATCH_SIZE
  end
end
