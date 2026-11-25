class SearchIndexing::ConversationSearch
  PER_PAGE = 25
  RESULT_WINDOW = 10_000
  BATCH_SIZE = 500
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
    while offset < RESULT_WINDOW
      hits = search_hits(offset)
      accessible = accessible_conversations(hits)
      hits.each_with_index do |hit, position|
        conversation = accessible[conversation_id(hit)]
        next unless conversation

        yield conversation, offset + position
      end
      offset += hits.size
      break if hits.size < BATCH_SIZE
    end
  end

  def result(records, cursor)
    { conversations: records, next_cursor: cursor, has_more: cursor.present? }
  end

  def search_hits(offset)
    response = Searchkick.client.search(
      index: [Conversation.search_index.name, Message.search_index.name], search_type: 'dfs_query_then_fetch',
      body: @query.body.merge(from: offset, size: [BATCH_SIZE, RESULT_WINDOW - offset].min)
    )
    raise Searchkick::Error, 'Incomplete conversation search response' if response['timed_out'] || response.fetch('_shards').fetch('failed').positive?

    response.fetch('hits').fetch('hits')
  end

  def conversation_id(hit)
    hit.fetch('fields').fetch('conversation_id').first
  end

  def accessible_conversations(hits)
    candidates = @scope.where(id: hits.map { |hit| conversation_id(hit) })
    Conversations::PermissionFilterService.new(candidates, @user, @account, plan_hint_selective_filter: true).perform.index_by(&:id)
  end
end
