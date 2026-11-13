class SearchIndexingDispatchJob < ApplicationJob
  queue_as :search_indexing

  def perform
    return unless ChatwootApp.advanced_search_allowed?

    SearchIndexing::Store.due_streams.each do |stream|
      epoch, entity, account_id = stream.split(':')
      SearchIndexing::FlushJob.perform_later(entity, account_id.to_i, epoch)
    end
  end
end
