class SearchIndexing::AssociationRefreshJob < ApplicationJob
  queue_as :async_database_migration

  # Nullification bypasses conversation callbacks. Find the former references in
  # the index, then let Searchkick reload their current database state in batches.
  def perform(field, id, account_id = nil)
    return unless ChatwootApp.advanced_search_allowed? && Conversation.search_index.exists?

    Conversation.search_index.refresh
    SearchIndexing::IndexedConversations.new(account_id, filters: [{ term: { field => id } }]).each_batch do |hits|
      Searchkick::ProcessBatchJob.perform_now(class_name: 'Conversation', record_ids: hits.pluck('_id'), index_name: Conversation.search_index.name)
    end
  end
end
