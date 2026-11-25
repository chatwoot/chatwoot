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
        filter: [{ term: { account_id: @account.id } }, { terms: { inbox_id: @inbox_ids } }],
        should: [conversation_query, message_query], minimum_should_match: 1
      } },
      # Each conversation is ranked by its best hit, not by how many messages it has.
      collapse: { field: 'conversation_id' }, sort: [{ _score: :desc }, { conversation_id: :desc }]
    }
  end

  private

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
