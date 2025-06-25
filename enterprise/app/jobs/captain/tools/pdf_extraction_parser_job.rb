class Captain::Tools::PdfExtractionParserJob < ApplicationJob
  queue_as :low

  def perform(assistant_id:, pdf_content:, document_id: nil)
    assistant = Captain::Assistant.find(assistant_id)
    account = assistant.account

    if limit_exceeded?(account)
      Rails.logger.info("Document limit exceeded for assistant #{assistant_id}")
      return
    end

    return unless document_id.present?

    # Find the original document
    document = Captain::Document.find_by(id: document_id)
    return unless document

    # Extract content from PDF content hash
    content = pdf_content[:content] || ''
    page_number = pdf_content[:page_number] || 1
    chunk_index = pdf_content[:chunk_index] || 1
    total_chunks = pdf_content[:total_chunks] || 1

    # Append content to the original document
    append_content_to_document(document, content, page_number, chunk_index, total_chunks)

  rescue StandardError => e
    Rails.logger.error "Failed to parse PDF content for assistant #{assistant_id}: #{e.message}"
    
    # Mark the document as available even if there's an error, so it doesn't get stuck
    document&.update(status: 'available') if document_id.present?
    
    raise "Failed to parse PDF data: #{e.message}"
  end

  private

  def limit_exceeded?(account)
    limits = account.usage_limits.dig(:captain, :documents)
    return false unless limits
    
    limits[:current_available].to_i <= 0
  end

  def append_content_to_document(document, content, page_number, chunk_index, total_chunks)
    # Use Redis to coordinate content aggregation across multiple jobs
    redis_key = "pdf_content_#{document.id}"
    
    # Store this chunk's content in Redis with metadata
    chunk_data = {
      content: content,
      page_number: page_number,
      chunk_index: chunk_index,
      total_chunks: total_chunks,
      processed_at: Time.current.to_i
    }
    
    # Add chunk to Redis hash using Alfred
    $alfred.with do |conn|
      conn.hset(redis_key, "#{page_number}_#{chunk_index}", chunk_data.to_json)
      conn.expire(redis_key, 3600) # Expire after 1 hour
    end
    
    # Check if all chunks are processed
    all_chunks = $alfred.with { |conn| conn.hgetall(redis_key) }
    total_expected_chunks = calculate_total_expected_chunks(all_chunks)
    
    if all_chunks.size >= total_expected_chunks
      # All chunks processed, aggregate content
      aggregate_and_update_document(document, all_chunks, redis_key)
    end
  end
  
  def calculate_total_expected_chunks(all_chunks)
    # Calculate total expected chunks based on the chunks we have
    all_chunks.values.map do |chunk_json|
      chunk_data = JSON.parse(chunk_json)
      chunk_data['total_chunks']
    end.max || 1
  end
  
  def aggregate_and_update_document(document, all_chunks, redis_key)
    # Parse and sort chunks by page and chunk index
    sorted_chunks = all_chunks.map do |key, chunk_json|
      chunk_data = JSON.parse(chunk_json)
      [chunk_data['page_number'], chunk_data['chunk_index'], chunk_data['content']]
    end.sort_by { |page, chunk_idx, _| [page, chunk_idx] }
    
    # Combine all content
    combined_content = sorted_chunks.map(&:last).join("\n\n")
    
    # Update the document with combined content
    document.update!(
      content: combined_content[0..199_999], # Respect the 200k character limit
      status: 'available'
    )
    
    # Clean up Redis key
    $alfred.with { |conn| conn.del(redis_key) }
    
    Rails.logger.info "Successfully aggregated PDF content for document #{document.id}"
  end
end