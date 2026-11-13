class SearchIndexing::FlushJob < ApplicationJob
  queue_as :search_indexing

  def perform(entity, account_id, epoch)
    return unless ChatwootApp.advanced_search_allowed?
    return unless epoch == SearchIndexing::Store.epoch

    buffer = SearchIndexing::Buffer.new(entity: entity, account_id: account_id, epoch: epoch)
    batch = buffer.claim
    return unless batch

    outcomes = ActiveSupport::Notifications.instrument('flush.search_indexing', entity: entity, account_id: account_id) do
      ActiveRecord::Base.connected_to(role: :writing) do
        document = SearchIndexing::Registry.fetch(entity).new(account_id)
        SearchIndexing::BulkWriter.new(document: document, epoch: epoch).perform(batch)
      end
    end
    buffer.acknowledge(batch, outcomes)
    Rails.logger.info("Search indexing #{buffer.stream}: #{outcomes.pluck(:state).tally}")
  end
end
