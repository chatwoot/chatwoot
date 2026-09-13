module Captain::Apropos::QueryFunctions
  MAX_QUERY_REQUEST_BYTES = 10_000

  def query_data(instruction)
    unless instruction.is_a?(String) && instruction.strip.present? && instruction.bytesize <= MAX_QUERY_REQUEST_BYTES
      raise Captain::Apropos::Error, 'Query request must be a nonempty string of at most 10000 bytes'
    end

    consume_agent_call!
    record('query_request', { 'instruction' => instruction })
    response = Captain::Apropos::QueryAgentService.new(account: account, runtime: self, instruction: instruction).perform
    raise Captain::Apropos::Error, response[:error] if response[:error]

    response.fetch(:message)
  rescue StandardError => e
    record('error', { 'message' => e.message })
    raise
  end

  def query_next(reference)
    raise Captain::Apropos::Error, 'query-next expects a cursor reference string' unless reference.is_a?(String)

    cursor = scheme.bindings.fetch(reference.to_sym)
    unless cursor.is_a?(Hash) && cursor['kind'] == 'wootql_cursor'
      raise Captain::Apropos::Error, 'Expected a WootQL cursor returned by query-data or query-next'
    end

    query_page(cursor.fetch('source'), cursor.fetch('offset'))
  end

  def query_page(source, offset = 0)
    raise Captain::Apropos::Error, 'WootQL source must be a string' unless source.is_a?(String)

    record('query', { 'source' => source, 'offset' => offset })
    page = @query.run(source, {}, offset)
    rows = page.fetch('items')
    next_offset = page.fetch('next_offset')
    cursor = next_offset == false ? false : store({ 'kind' => 'wootql_cursor', 'source' => source, 'offset' => next_offset })
    result = {
      'source' => source, 'result_ref' => store(rows), 'count' => rows.size, 'offset' => offset,
      'next_cursor' => cursor, 'query_exhausted' => next_offset == false,
      'preview' => Captain::Apropos::ContextLimits.preview(rows)
    }
    record('result', { 'value' => result })
    result
  end

  def query_schema
    Captain::Apropos::WootqlSchema.describe(@data)
  end

  def query_map(function, page)
    unless function.is_a?(Proc) || function.is_a?(Captain::Apropos::Scheme::Closure)
      raise Captain::Apropos::Error, 'query-map expects a function and a page returned by query-data or query-next'
    end

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

  def process_query_pages(function, progress)
    loop do
      process_query_page(function, progress)
      cursor = progress.fetch('page').fetch('next_cursor')
      break if cursor == false

      progress['page'] = query_next(cursor)
      progress['page_processed'] = false
    end
  end

  def process_query_page(function, progress)
    rows = scheme.bindings.fetch(progress.fetch('page').fetch('result_ref').to_sym)
    unless rows.empty?
      result = scheme.invoke(function, [rows])
      progress['result_refs'] << store(result)
      progress['processed_rows'] += rows.size
    end
    progress['processed_pages'] += 1
    progress['page_processed'] = true
  end
end
