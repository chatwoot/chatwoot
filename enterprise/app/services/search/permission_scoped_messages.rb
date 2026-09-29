class Search::PermissionScopedMessages
  BATCH_SIZE = 1000

  pattr_initialize [:search!, :scope!]

  def records(page:, per_page:)
    offset = ([page.to_i, 1].max - 1) * per_page
    message_ids = []
    each_permitted_batch do |ids|
      if offset >= ids.length
        offset -= ids.length
        next
      end

      message_ids.concat(ids.drop(offset).take(per_page - message_ids.length))
      offset = 0
      break if message_ids.length == per_page
    end

    messages = scope.where(id: message_ids).index_by(&:id)
    message_ids.filter_map { |id| messages[id] }
  end

  private

  def each_permitted_batch
    results = search.load
    until results.hits.empty?
      ids = results.hits.map { |hit| hit.fetch('_id').to_i }
      # Keep indexed ordering while applying current permissions in SQL before pagination.
      yield ids & scope.where(id: ids).pluck(:id)
      results = results.scroll
    end
  ensure
    # Release the search context even when a result page fills before the final batch.
    results&.clear_scroll
  end
end
