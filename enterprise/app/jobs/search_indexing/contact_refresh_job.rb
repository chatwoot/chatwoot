class SearchIndexing::ContactRefreshJob < ApplicationJob
  queue_as :search_indexing

  def perform(entity, account_id, epoch)
    return unless ChatwootApp.advanced_search_allowed?
    return unless epoch == SearchIndexing::Store.epoch

    buffer = SearchIndexing::Buffer.new(entity: entity, account_id: account_id, epoch: epoch)
    batch = buffer.claim(limit: 1)
    return unless batch

    ActiveRecord::Base.connected_to(role: :writing) { refresh_page(buffer, batch) }
  end

  private

  def refresh_page(buffer, batch)
    contact_id, revision = batch.fetch(:revisions).first
    ids = Conversation.where(account_id: buffer.account_id, contact_id: contact_id)
                      .where('id > ?', buffer.progress(batch)).order(:id).limit(SearchIndexing::Buffer::BATCH_SIZE).pluck(:id)
    SearchIndexing::Buffer.new(entity: 'conversations', account_id: buffer.account_id, epoch: buffer.epoch).enqueue(ids)
    if ids.size == SearchIndexing::Buffer::BATCH_SIZE
      buffer.advance(batch, ids.last)
    else
      buffer.acknowledge(batch, [{ id: contact_id, revision: revision, state: 'success' }])
    end
  end
end
