class Search::PermissionScopedMessages
  BATCH_SIZE = 1000
  MAX_CANDIDATES = 10_000

  pattr_initialize [:search!, :scope!]
  attr_reader :next_sort, :remaining_offset

  def records(page:, per_page:, continuation: nil)
    @remaining_offset = continuation ? continuation.fetch('offset') : ([page.to_i, 1].max - 1) * per_page
    @next_sort = continuation&.fetch('after')
    @message_ids = []
    (MAX_CANDIDATES / BATCH_SIZE).times do
      break if scan_batch(fetch_hits, per_page)
    end

    messages = scope.where(id: @message_ids).index_by(&:id)
    @message_ids.filter_map { |id| messages[id] }
  end

  private

  def fetch_hits
    body_options = { track_total_hits: false }
    body_options[:search_after] = next_sort if next_sort
    results = search.call(limit: BATCH_SIZE, load: false, select: [], body_options: body_options,
                          request_params: { allow_partial_search_results: false })
    raise Searchkick::Error, 'Indexed message search timed out' if results.response['timed_out']

    results.hits
  end

  def scan_batch(hits, per_page)
    permitted = permitted_hits(hits)
    skip = [remaining_offset, permitted.size].min
    selected = permitted.drop(skip).take(per_page - @message_ids.size)
    @remaining_offset -= skip
    @message_ids.concat(selected.map { |hit| message_id(hit) })

    page_filled = @message_ids.size == per_page
    # Leave the rest of the batch for the next request when the page fills early.
    last_consumed = page_filled ? selected.last : hits.last
    exhausted = hits.size < BATCH_SIZE && last_consumed == hits.last
    @next_sort = exhausted ? nil : continuation_sort(last_consumed)
    exhausted || page_filled
  end

  def permitted_hits(hits)
    ids = hits.map { |hit| message_id(hit) }
    permitted_ids = scope.where(id: ids).pluck(:id).to_set
    hits.select { |hit| permitted_ids.include?(message_id(hit)) }
  end

  def continuation_sort(hit)
    sort = hit.fetch('sort')
    # Older documents may lack the indexed ID used to break timestamp ties.
    raise Searchkick::Error, 'Message index is missing the pagination sort field' unless sort.last == message_id(hit)

    sort
  end

  def message_id(hit)
    hit.fetch('_id').to_i
  end
end
