class SearchIndexing::ConversationSearch
  CANDIDATE_LIMIT = 1000
  FIELDS = %w[display_id_text mail_subject].freeze
  RECOVERABLE_ERRORS = [Faraday::Error, Searchkick::Error, OpenSearch::Transport::Transport::Errors::NotFound,
                        OpenSearch::Transport::Transport::Errors::TooManyRequests, OpenSearch::Transport::Transport::Errors::RequestTimeout,
                        OpenSearch::Transport::Transport::Errors::InternalServerError, OpenSearch::Transport::Transport::Errors::BadGateway,
                        OpenSearch::Transport::Transport::Errors::ServiceUnavailable, OpenSearch::Transport::Transport::Errors::GatewayTimeout].freeze

  def initialize(account, query, inbox_ids)
    @account = account
    @query = query
    @inbox_ids = inbox_ids
  end

  def ids
    return unless supported? && SearchIndexing::Conversations.enabled?(@account)

    response = Searchkick.client.search(index: Conversation.search_index.name, body: search_body)
    raise Searchkick::Error, 'Incomplete conversation search response' if response['timed_out'] || response.fetch('_shards').fetch('failed').positive?

    ids = complete_ids(response)
    Rails.logger.info("Conversation search backend=opensearch account_id=#{@account.id} candidates=#{ids.size}") if ids
    ids
  rescue *RECOVERABLE_ERRORS => e
    Rails.logger.warn("Conversation search backend=sql account_id=#{@account.id} error=#{e.class}")
    nil
  end

  private

  def complete_ids(response)
    hits = response.fetch('hits')
    total = hits.fetch('total')
    return unless total.fetch('relation') == 'eq' && total.fetch('value') <= CANDIDATE_LIMIT
    return unless hits.fetch('hits').size == total.fetch('value')

    hits.fetch('hits').map { |hit| Integer(hit.fetch('_id'), 10) }
  end

  def supported?
    @query.ascii_only? && @query.length.between?(3, 256) && !@query.match?(/[%_\\]/)
  end

  def search_body
    {
      size: CANDIDATE_LIMIT + 1, track_total_hits: true, timeout: '1s', _source: false,
      query: { bool: {
        filter: [{ term: { account_id: @account.id } }, { terms: { inbox_id: @inbox_ids } }],
        must: [{ multi_match: { query: @query, fields: FIELDS, type: 'phrase' } }]
      } }
    }
  end
end
