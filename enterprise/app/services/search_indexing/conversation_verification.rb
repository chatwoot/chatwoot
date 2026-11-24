class SearchIndexing::ConversationVerification
  def initialize(account)
    @account = account
    @report = { checked: 0, missing: 0, stale: 0, orphaned: 0, verified: false }
  end

  def perform(activate: false)
    raise ArgumentError, 'Enable advanced_search_conversations before verifying' unless SearchIndexing::Conversations.enabled?(@account)

    account_updated_at = @account.reload.updated_at
    index_identity = SearchIndexing::IndexVerification.identity
    verify_source_records
    remove_orphans
    Conversation.search_index.refresh
    clean = @report.values_at(:missing, :stale, :orphaned).all?(&:zero?)
    if clean && activate
      @report[:verified] = SearchIndexing::IndexVerification.record!(@account, index_identity, account_updated_at: account_updated_at)
    end
    @report.merge(clean: clean, pending_live_ids: Conversation.search_index.reindex_queue.length, index: index_identity)
  end

  private

  def verify_source_records
    Conversation.search_index.refresh
    upper_id = @account.conversations.maximum(:id) || 0
    @account.conversations.where(id: ..upper_id).search_import.find_in_batches(batch_size: SearchIndexing::Conversations::BATCH_SIZE) do |records|
      verify_records(records)
    end
  end

  def verify_records(records)
    records = records.select(&:should_index?)
    return if records.empty?

    documents = indexed_documents(records)
    repairs = records.filter_map do |record|
      next unless repair_needed?(record, documents[record.id.to_s])

      record.id.to_s
    end
    repair(repairs)
  end

  def indexed_documents(records)
    body = { size: records.size, query: { bool: { filter: [{ term: { account_id: @account.id } }, { ids: { values: records.map(&:id) } }] } } }
    response = Searchkick.client.search(index: Conversation.search_index.name, body: body)
    SearchIndexing::IndexedConversations.check_response!(response)
    response.fetch('hits').fetch('hits').index_by { |document| document.fetch('_id') }
  end

  def repair_needed?(record, document)
    @report[:checked] += 1
    return false if document && document.fetch('_source') == record.search_data.as_json

    @report[document ? :stale : :missing] += 1
    true
  end

  def remove_orphans
    SearchIndexing::IndexedConversations.new(@account.id).each_batch do |hits|
      ids = hits.pluck('_id')
      records = @account.conversations.where(id: ids).search_import.select(&:should_index?)
      orphans = ids - records.map { |record| record.id.to_s }
      @report[:orphaned] += orphans.size
      repair(orphans)
    end
  end

  def repair(ids)
    return if ids.empty?

    # A failed repair must not leave previously verified, now incomplete data active.
    SearchIndexing::IndexVerification.clear!(@account) unless @verification_cleared
    @verification_cleared = true
    Searchkick::ProcessBatchJob.perform_now(class_name: 'Conversation', record_ids: ids, index_name: Conversation.search_index.name)
  end
end
