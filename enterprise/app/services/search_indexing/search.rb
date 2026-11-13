class SearchIndexing::Search
  MAX_CANDIDATES = 1_000
  MAX_QUERY_LENGTH = 256
  MAX_LAG = 2.minutes
  UNAVAILABLE_ERRORS = [Faraday::ConnectionFailed, Faraday::TimeoutError, Redis::BaseConnectionError,
                        OpenSearch::Transport::Transport::Errors::NotFound,
                        OpenSearch::Transport::Transport::Errors::TooManyRequests,
                        OpenSearch::Transport::Transport::Errors::InternalServerError,
                        OpenSearch::Transport::Transport::Errors::BadGateway,
                        OpenSearch::Transport::Transport::Errors::ServiceUnavailable,
                        OpenSearch::Transport::Transport::Errors::GatewayTimeout].freeze

  def initialize(account:, query:, inbox_ids: nil)
    @account = account
    @query = query
    @inbox_ids = inbox_ids
  end

  def narrow(scope)
    return fallback(scope, 'unsupported_query') unless supported_query?
    return fallback(scope, 'unready_or_lagging') unless ready?

    ids = candidate_ids
    return fallback(scope, 'incomplete_or_broad') if ids.nil?

    # Keep current permissions, LIKE semantics, sorting and pagination in SQL.
    # The engine supplies all candidates, never a page that could underfill after authorization.
    scope.where(id: ids)
  rescue *UNAVAILABLE_ERRORS => e
    Rails.logger.warn("Search indexing read fallback: conversations / #{e.class.name}")
    fallback(scope, e.class.name)
  end

  private

  def fallback(scope, reason)
    ActiveSupport::Notifications.instrument('fallback.search_indexing', entity: 'conversations', account_id: @account.id, reason: reason)
    scope
  end

  def supported_query?
    @query.length.between?(3, MAX_QUERY_LENGTH) && @query.ascii_only? && !@query.match?(/[%_\\]/)
  end

  def ready?
    @state = SearchIndexing::IndexState.find_by(account_id: @account.id, entity: 'conversations')
    return false unless @state&.readable?

    %w[conversations contact_conversations].all? { |entity| buffer_healthy?(entity) }
  end

  def buffer_healthy?(entity)
    statistics = SearchIndexing::Buffer.new(entity: entity, account_id: @account.id, epoch: @state.epoch).statistics
    statistics[:failed].zero? && (!statistics[:oldest_at] || statistics[:oldest_at] >= MAX_LAG.ago.to_f)
  end

  def candidate_ids
    response = ActiveSupport::Notifications.instrument('search.search_indexing', entity: 'conversations', account_id: @account.id) do
      Searchkick.client.search(index: @state.document.index_name(@state.epoch), allow_partial_search_results: false, body: query_body)
    end
    return if response.fetch('timed_out') || response.fetch('_shards').fetch('failed').positive?

    hits = response.fetch('hits').fetch('hits')
    return if hits.length > MAX_CANDIDATES

    hits.map { |hit| Integer(hit.fetch('_id')) }
  end

  def query_body
    matches = search_fields.map { |field| { match_phrase: { field => @query } } }
    filters = [{ term: { account_id: @account.id } }, { term: { deleted: false } }, { bool: { should: matches, minimum_should_match: 1 } }]
    filters << { terms: { inbox_id: @inbox_ids } } if @inbox_ids
    {
      size: MAX_CANDIDATES + 1, _source: false, track_total_hits: false, sort: ['_doc'], timeout: '2s',
      query: { bool: { filter: filters } }
    }
  end

  def search_fields
    SearchIndexing::ConversationDocument::CONTACT_FIELDS.map { |field| "contact.#{field}" } + %w[display_id_text mail_subject]
  end
end
