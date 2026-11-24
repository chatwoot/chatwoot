class SearchIndexing::IndexedConversations
  def initialize(account_id, filters: [])
    @account_id = account_id
    @filters = filters
  end

  def each_batch
    scroll_id = nil
    response = Searchkick.client.search(
      index: Conversation.search_index.name, scroll: '1m',
      body: { query: { bool: { filter: filters } }, sort: ['_doc'], size: SearchIndexing::Conversations::BATCH_SIZE,
              docvalue_fields: SearchIndexing::ConversationDocument::FILTER_ATTRIBUTES }
    )
    loop do
      scroll_id = response.fetch('_scroll_id')
      self.class.check_response!(response)
      hits = response.fetch('hits').fetch('hits')
      break if hits.empty?

      yield hits
      response = Searchkick.client.scroll(scroll_id: scroll_id, scroll: '1m')
    end
  ensure
    Searchkick.client.clear_scroll(scroll_id: scroll_id) if scroll_id
  end

  def self.check_response!(response)
    raise Searchkick::Error, 'Incomplete conversation search response' if response['timed_out'] || response.fetch('_shards').fetch('failed').positive?
  end

  private

  def filters
    @account_id ? @filters + [{ term: { account_id: @account_id } }] : @filters
  end
end
