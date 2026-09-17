module Captain::Apropos::QueryFunctions
  def query_next(page)
    validate_query_page!(page)
    return false if page['next_offset'] == false

    query_run(page.fetch('source'), page.fetch('parameters'), page.fetch('next_offset'))
  end

  def query_run(source, parameters = {}, offset = 0)
    raise Captain::Apropos::Error, 'WootQL source must be a string' unless source.is_a?(String)
    raise Captain::Apropos::Error, 'WootQL parameters must be a hash' unless parameters.is_a?(Hash)

    record('query', { 'source' => source, 'parameters' => parameters, 'offset' => offset })
    @query.run(source, parameters, offset).merge('source' => source, 'parameters' => parameters, 'offset' => offset)
  end

  def query_map(function, page)
    unless function.is_a?(Proc) || function.is_a?(Captain::Apropos::Scheme::Closure)
      raise Captain::Apropos::Error, 'query-map expects a function and a page returned by query-run or query-next'
    end

    validate_query_page!(page)

    progress = { 'status' => 'running', 'page' => page, 'page_processed' => false,
                 'processed_rows' => 0, 'processed_pages' => 0, 'result_refs' => [] }
    reference = store(progress)
    process_query_pages(function, progress)
    progress['status'] = 'completed'
    progress.except('page', 'page_processed').merge('progress_ref' => reference, 'query_exhausted' => true)
  rescue StandardError => e
    raise unless reference

    progress['status'] = 'failed'
    raise e.exception("#{e.message}. Query progress saved at #{reference}; inspect it and receipts before retrying callbacks.")
  end

  private

  def validate_query_page!(page)
    required_keys = %w[items next_offset source parameters offset]
    return if page.is_a?(Hash) && required_keys.all? { |key| page.key?(key) }

    raise Captain::Apropos::Error, 'Expected a WootQL page returned by query-run or query-next'
  end

  def process_query_pages(function, progress)
    loop do
      process_query_page(function, progress)
      next_page = query_next(progress.fetch('page'))
      break if next_page == false

      progress['page'] = next_page
      progress['page_processed'] = false
    end
  end

  def process_query_page(function, progress)
    rows = progress.fetch('page').fetch('items')
    unless rows.empty?
      result = scheme.invoke(function, [rows])
      progress['result_refs'] << store(result)
      progress['processed_rows'] += rows.size
    end
    progress['processed_pages'] += 1
    progress['page_processed'] = true
  end
end
