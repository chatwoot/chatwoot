class SearchIndexing::ConversationSearch
  PER_PAGE = 25
  RESULT_WINDOW = 10_000
  BATCH_SIZE = 500
  MESSAGE_COUNT_WEIGHT = 0.15
  MAX_MESSAGE_COUNT_BOOST = 0.5
  RECOVERABLE_ERRORS = [Faraday::Error, Searchkick::Error, OpenSearch::Transport::Transport::Errors::NotFound,
                        OpenSearch::Transport::Transport::Errors::TooManyRequests, OpenSearch::Transport::Transport::Errors::RequestTimeout,
                        OpenSearch::Transport::Transport::Errors::InternalServerError, OpenSearch::Transport::Transport::Errors::BadGateway,
                        OpenSearch::Transport::Transport::Errors::ServiceUnavailable, OpenSearch::Transport::Transport::Errors::GatewayTimeout].freeze

  def initialize(account:, user:, query:, scope:)
    @account = account
    @user = user
    @scope = scope
    @query = query
  end

  def perform(cursor: nil, page: 1)
    offset = cursor.present? ? Integer(cursor.to_s, 10) : ([page.to_i, 1].max - 1) * PER_PAGE
    raise ArgumentError, 'Invalid conversation search cursor' if offset.negative?

    records = []
    each_conversation(offset) do |conversation, position|
      return result(records, position.to_s) if records.size == PER_PAGE

      records << conversation
    end
    result(records, nil)
  end

  private

  def each_conversation(offset)
    return if offset >= RESULT_WINDOW

    ranked_hits.drop(offset).each_slice(BATCH_SIZE) do |hits|
      accessible = accessible_conversations(hits)
      hits.each_with_index do |hit, position|
        conversation = accessible[conversation_id(hit)]
        next unless conversation

        yield conversation, offset + position
      end
      offset += hits.size
    end
  end

  def result(records, cursor)
    { conversations: records, next_cursor: cursor, has_more: cursor.present? }
  end

  def ranked_hits
    hits = search_hits
    return hits if hits.empty?

    counts = matching_message_counts(hits)
    hits.sort_by { |hit| [-ranking_score(hit, counts.fetch(conversation_id(hit), 0)), -conversation_id(hit)] }
  end

  def search_hits
    response = search_response(
      index: [Conversation.search_index.name, Message.search_index.name], search_type: 'dfs_query_then_fetch',
      body: @query.body.merge(size: RESULT_WINDOW)
    )
    response.fetch('hits').fetch('hits')
  end

  def matching_message_counts(hits)
    response = search_response(index: Message.search_index.name, body: @query.message_counts_body(hits.map { |hit| conversation_id(hit) }))
    response.fetch('aggregations').fetch('conversations').fetch('buckets').to_h { |bucket| [bucket.fetch('key'), bucket.fetch('doc_count')] }
  end

  def ranking_score(hit, count)
    # Repeated matches help, but volume can increase the best relevance score by at most 50%.
    bonus = [MESSAGE_COUNT_WEIGHT * Math.log([count, 1].max), MAX_MESSAGE_COUNT_BOOST].min
    hit.fetch('_score') * (1 + bonus)
  end

  def search_response(**)
    response = Searchkick.client.search(**)
    raise Searchkick::Error, 'Incomplete conversation search response' if response['timed_out'] || response.fetch('_shards').fetch('failed').positive?

    response
  end

  def conversation_id(hit)
    hit.fetch('fields').fetch('conversation_id').first
  end

  def accessible_conversations(hits)
    candidates = @scope.where(id: hits.map { |hit| conversation_id(hit) })
    Conversations::PermissionFilterService.new(candidates, @user, @account, plan_hint_selective_filter: true).perform.index_by(&:id)
  end
end
