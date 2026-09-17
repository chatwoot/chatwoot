module Captain::Apropos::QueryFunctions
  def query_run(source, parameters = {}, offset = 0)
    raise Captain::Apropos::Error, 'WootQL source must be a string' unless source.is_a?(String)
    raise Captain::Apropos::Error, 'WootQL parameters must be an object' unless parameters.is_a?(Hash)

    record('query', { 'source' => source, 'parameters' => parameters, 'offset' => offset })
    prepared = @query.prepare(source, parameters)
    reference = "query-#{SecureRandom.hex(8)}"
    @prepared_queries[reference] = { prepared: prepared, source: source, parameters: parameters }
    query_page(reference, offset)
  end

  def query_next(page)
    validate_query_page!(page)
    return false unless page.fetch('has_more')

    query_page(page.fetch('query_ref'), page.fetch('next_offset'))
  end

  def query_map(function, page)
    raise Captain::Apropos::Error, 'query-map expects a procedure followed by a query page' unless Captain::Apropos::SchemeValues.procedure?(function)

    validate_query_page!(page)
    progress = {
      'kind' => 'processing_result', 'status' => 'running', 'page' => page, 'page_processed' => false,
      'processed_item_count' => 0, 'processed_page_count' => 0, 'results' => [], 'query_exhausted' => false
    }
    reference = store(progress)
    loop do
      items = progress.fetch('page').fetch('items')
      unless items.empty?
        result = scheme.call(function, [items])
        progress['results'] << stored_result(result)
        progress['processed_item_count'] += items.size
      end
      progress['processed_page_count'] += 1
      progress['page_processed'] = true
      save_query_progress(reference, progress)
      next_page = query_next(progress.fetch('page'))
      break if next_page == false

      progress['page'] = next_page
      progress['page_processed'] = false
      save_query_progress(reference, progress)
    end
    progress['status'] = 'completed'
    progress['query_exhausted'] = true
    save_query_progress(reference, progress)
    progress.except('page', 'page_processed').merge('progress_ref' => reference)
  rescue StandardError => e
    raise unless reference

    progress['status'] = 'failed'
    save_query_progress(reference, progress)
    raise e.exception("#{e.message}. Progress is saved at #{reference}; completed results and receipts survive. No callbacks were retried.")
  end

  private

  def query_page(reference, offset)
    query = @prepared_queries.fetch(reference) do
      raise Captain::Apropos::Error, 'This query handle is not active in this turn. Start a new query; saved page items are still available.'
    end
    if offset.positive?
      record('query', { 'source' => query.fetch(:source), 'parameters' => query.fetch(:parameters), 'offset' => offset, 'query_ref' => reference })
    end
    page = query.fetch(:prepared).page(offset)
    page.merge('kind' => 'page', 'item_count' => page.fetch('items').size, 'has_more' => page.fetch('next_offset') != false,
               'query_ref' => reference, 'offset' => offset)
  end

  def validate_query_page!(page)
    unless page.is_a?(Hash) && page['kind'] == 'page' && page['items'].is_a?(Array) &&
           page['query_ref'].is_a?(String) && [true, false].include?(page['has_more']) && page.key?('next_offset')
      raise Captain::Apropos::Error, 'Expected a query page, not a preview, item list, count, or saved reference'
    end
  end

  def stored_result(value)
    { 'kind' => 'stored_value', 'ref' => store(value), 'value_info' => Captain::Apropos::ContextLimits.describe(value) }
  end

  def save_query_progress(reference, progress)
    scheme.bind(reference, Captain::Apropos::SchemeValues.from_ruby(progress))
  end
end
