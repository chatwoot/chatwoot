class Captain::Tools::PdfExtractionParserJob < ApplicationJob
  queue_as :low
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  # Redis and content management settings
  REDIS_KEY_TTL = 7200     # 2 hours - increased for larger PDFs
  DB_STORAGE_LIMIT = 50_000  # Store only first 50k chars in DB for search/preview

  def perform(assistant_id:, pdf_content:, document_id: nil)
    validate_inputs!(assistant_id, pdf_content, document_id)

    assistant = load_assistant(assistant_id)
    return if processing_should_skip?(assistant)

    document = load_document(document_id)
    return unless document

    content_data = extract_content_data(pdf_content)
    log_chunk_processing(document_id, content_data)

    append_content_to_document(document, content_data)
  rescue ActiveRecord::RecordNotFound => e
    handle_record_not_found_error(e, document_id)
  rescue StandardError => e
    handle_processing_error(e, assistant_id, document_id)
  end

  private

  def validate_inputs!(assistant_id, pdf_content, document_id)
    raise ArgumentError, 'Assistant ID is required' if assistant_id.blank?
    raise ArgumentError, 'PDF content is required' if pdf_content.blank?
    raise ArgumentError, 'Document ID is required' if document_id.blank?
  end

  def extract_content_data(pdf_content)
    {
      content: pdf_content[:content] || '',
      page_number: pdf_content[:page_number] || 1,
      chunk_index: pdf_content[:chunk_index] || 1,
      total_chunks: pdf_content[:total_chunks] || 1
    }
  end

  def mark_document_as_available(document_id)
    return if document_id.blank?

    Captain::Document.find_by(id: document_id)&.update(status: 'available')
  rescue StandardError => e
    Rails.logger.error "Failed to mark document #{document_id} as available: #{e.message}"
  end

  def limit_exceeded?(account)
    limits = account.usage_limits.dig(:captain, :documents)
    return false unless limits

    limits[:current_available].to_i <= 0
  end

  def build_redis_key(document_id)
    "pdf_content_#{document_id}"
  end

  def build_chunk_data(content_data)
    {
      content: content_data[:content],
      page_number: content_data[:page_number],
      chunk_index: content_data[:chunk_index],
      total_chunks: content_data[:total_chunks],
      processed_at: Time.current.to_i
    }
  end

  def store_chunk_in_redis(redis_key, content_data, chunk_data)
    chunk_key = "#{content_data[:page_number]}_#{content_data[:chunk_index]}"

    redis_connection.with do |conn|
      conn.hset(redis_key, chunk_key, chunk_data.to_json)
      conn.expire(redis_key, REDIS_KEY_TTL)
    end
  end

  def retrieve_all_chunks(redis_key)
    redis_connection.with { |conn| conn.hgetall(redis_key) }
  end

  def ready_for_aggregation?(current_chunks, expected_chunks)
    current_chunks >= expected_chunks
  end

  def parse_and_sort_chunks(all_chunks)
    parsed_chunks = all_chunks.map do |_key, chunk_json|
      chunk_data = JSON.parse(chunk_json)
      [chunk_data['page_number'], chunk_data['chunk_index'], chunk_data['content']]
    end

    parsed_chunks.sort_by { |page, chunk_idx, _| [page, chunk_idx] }
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse chunk JSON: #{e.message}"
    raise 'Invalid chunk data format'
  end

  def combine_chunks_content(sorted_chunks)
    sorted_chunks.map(&:last).join("\n\n")
  end

  def cleanup_redis_key(redis_key)
    redis_connection.with { |conn| conn.del(redis_key) }
  rescue Redis::BaseError => e
    Rails.logger.warn "Failed to cleanup Redis key #{redis_key}: #{e.message}"
  end

  def append_content_to_document(document, content_data)
    redis_key = build_redis_key(document.id)

    chunk_data = build_chunk_data(content_data)

    store_chunk_in_redis(redis_key, content_data, chunk_data)

    # Process each chunk individually with response builder
    Captain::Documents::ResponseBuilderJob.perform_later(document, content_data[:content])

    all_chunks = retrieve_all_chunks(redis_key)
    total_expected_chunks = calculate_total_expected_chunks(all_chunks)

    finalize_document_processing(document, all_chunks, redis_key) if ready_for_aggregation?(all_chunks.size, total_expected_chunks)
  rescue Redis::BaseError => e
    Rails.logger.error "Redis error during PDF content processing: #{e.message}"
    raise 'Failed to process PDF content due to storage error'
  end

  def calculate_total_expected_chunks(all_chunks)
    # Calculate total expected chunks based on the chunks we have
    all_chunks.values.map do |chunk_json|
      chunk_data = JSON.parse(chunk_json)
      chunk_data['total_chunks']
    end.max || 1
  end

  def finalize_document_processing(document, all_chunks, redis_key)
    sorted_chunks = parse_and_sort_chunks(all_chunks)
    combined_content = combine_chunks_content(sorted_chunks)

    log_document_processing_summary(document, all_chunks, combined_content)

    update_document_with_content(document, combined_content)
    cleanup_redis_key(redis_key)

    Rails.logger.info "PDF content finalized for document #{document.id}: #{combined_content.length} characters"
  rescue ActiveRecord::RecordInvalid => e
    handle_document_update_error(e, document, redis_key)
  end

  def log_document_processing_summary(document, all_chunks, combined_content)
    log_finalization_info(document, all_chunks, combined_content)
    chunk_summary = all_chunks.map do |_key, chunk_json|
      chunk_data = JSON.parse(chunk_json)
      "Page #{chunk_data['page_number']} Chunk #{chunk_data['chunk_index']}"
    end
    Rails.logger.info "Document #{document.id} chunks processed: #{chunk_summary.join(', ')}"
  end

  def update_document_with_content(document, combined_content)
    db_content = prepare_content_for_storage(combined_content)

    ActiveRecord::Base.transaction do
      document.update!(
        content: db_content,
        status: 'available',
        processed_at: Time.current
      )
      Rails.logger.info "Document #{document.id} content saved: #{db_content.length} characters"
    end
  end

  def prepare_content_for_storage(combined_content)
    return combined_content if combined_content.length <= DB_STORAGE_LIMIT

    "#{combined_content[0, DB_STORAGE_LIMIT]}... [Content truncated for storage - full content processed by AI]"
  end

  def handle_document_update_error(error, document, redis_key)
    Rails.logger.error "Failed to update document #{document.id}: #{error.message}"
    cleanup_redis_key(redis_key)
    raise
  end
end