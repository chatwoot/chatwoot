class SearchIndexing::ConversationSearchQuery
  MESSAGE_FIELDS = %w[content attachments.transcribed_text content_attributes.email.subject].freeze

  def initialize(account, query, inbox_ids, message_since)
    @account = account
    @query = query
    @inbox_ids = inbox_ids
    @message_since = message_since
  end

  def body
    {
      timeout: '1s', _source: false, fields: ['conversation_id'], track_total_hits: false,
      query: { bool: {
        filter: account_filters,
        should: [conversation_query, message_query], minimum_should_match: 1
      } },
      # Select the candidate window by its best hits before applying the matching-message bonus.
      collapse: { field: 'conversation_id' }, sort: [{ _score: :desc }, { conversation_id: :desc }]
    }
  end

  def message_counts_body(conversation_ids)
    {
      timeout: '1s', size: 0, track_total_hits: false,
      query: { bool: { filter: account_filters + [{ terms: { conversation_id: conversation_ids } }], must: message_query } },
      # Include every candidate on every shard so counts do not depend on shard-local top buckets.
      aggs: { conversations: { terms: { field: 'conversation_id', size: conversation_ids.size,
                                        shard_size: conversation_ids.size, order: { _key: :asc } } } }
    }
  end

  private

  def account_filters
    [{ term: { account_id: @account.id } }, { terms: { inbox_id: @inbox_ids } }]
  end

  def conversation_query
    { bool: {
      filter: { term: { _index: Conversation.search_index.name } },
      must: { multi_match: { query: @query, fields: %w[display_id_text mail_subject], type: 'phrase' } }
    } }
  end

  def message_query
    # Reuse Searchkick's analyzed fields and matching rules from the message search tab.
    query = Searchkick.search(@query, model: Message, fields: MESSAGE_FIELDS,
                                      where: { created_at: { gte: @message_since } }).body.fetch(:query)
    { bool: { filter: { term: { _index: Message.search_index.name } }, must: query } }
  end
end
