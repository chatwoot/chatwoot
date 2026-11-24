class SearchIndexing::ConversationFilter
  SORTS = {
    'last_activity_at_asc' => %w[last_activity_at asc], 'last_activity_at_desc' => %w[last_activity_at desc],
    'created_at_asc' => %w[created_at asc], 'created_at_desc' => %w[created_at desc],
    'latest' => %w[last_activity_at desc], 'sort_on_created_at' => %w[created_at asc]
  }.freeze

  def initialize(account, user, params)
    @account = account
    @user = user
    @params = params
  end

  def perform
    return unless eligible?

    query = supported_query
    return unless query && SearchIndexing::IndexVerification.ready?(@account, version: 2)

    response = Searchkick.client.search(index: Conversation.search_index.name, body: search_body(query))
    SearchIndexing::IndexedConversations.check_response!(response)
    result(response)
  rescue *SearchIndexing::ConversationSearch::RECOVERABLE_ERRORS => e
    Rails.logger.warn("Conversation filters backend=sql account_id=#{@account.id} error=#{e.class}")
    nil
  end

  private

  def eligible?
    SearchIndexing::Conversations.enabled?(@account) && @account.account_users.find_by(user: @user)&.administrator?
  end

  def supported_query
    sort_key = @params[:sort_by].to_s
    sort_key = ::Conversations::SortService::DEFAULT_SORT unless ::Conversations::SortService::SORT_OPTIONS.key?(sort_key)
    @sort = SORTS[sort_key]
    @offset = [@params[:page].to_i - 1, 0].max * Conversation.default_per_page
    return unless @sort && @offset + Conversation.default_per_page <= 10_000

    SearchIndexing::ConversationFilterConditions.new(@params[:payload]).query
  end

  def search_body(query)
    {
      from: @offset, size: Conversation.default_per_page, _source: false, track_total_hits: true, timeout: '1s',
      query: { bool: { filter: [{ term: { account_id: @account.id } }, query] } },
      sort: [{ @sort.first => @sort.last }, { id: @sort.last }],
      aggs: {
        mine: { filter: { term: { assignee_id: @user.id } } },
        unassigned: { filter: { bool: { must_not: [{ exists: { field: 'assignee_id' } }, { exists: { field: 'assignee_agent_bot_id' } }] } } }
      }
    }
  end

  def result(response)
    hits = response.fetch('hits')
    return unless hits.fetch('total').fetch('relation') == 'eq'

    total = hits.fetch('total').fetch('value')
    ids = hits.fetch('hits').map { |hit| Integer(hit.fetch('_id'), 10) }
    return unless ids.size == (total - @offset).clamp(0, Conversation.default_per_page)

    unassigned = response.fetch('aggregations').fetch('unassigned').fetch('doc_count')
    mine = response.fetch('aggregations').fetch('mine').fetch('doc_count')
    { ids: ids, count: { mine_count: mine, assigned_count: total - unassigned, unassigned_count: unassigned, all_count: total } }
  end
end
