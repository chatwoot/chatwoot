require 'securerandom'

class Captain::Tools::PdfExtractionParserJob < ApplicationJob
  queue_as :low
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(assistant_id:, pdf_content:, document_id: nil)
    validate_inputs!(assistant_id, pdf_content, document_id)

    assistant = load_assistant(assistant_id)
    content_data = extract_content_data(pdf_content)

    process_document(assistant, content_data, document_id)
  rescue ActiveRecord::RecordNotFound => e
    handle_record_not_found_error(e, document_id)
  rescue StandardError => e
    handle_processing_error(e, assistant_id, document_id)
  end

  private

  def validate_inputs!(assistant_id, pdf_content, _document_id)
    raise ArgumentError, 'Assistant ID is required' if assistant_id.blank?
    raise ArgumentError, 'PDF content is required' if pdf_content.blank?
  end

  def extract_content_data(pdf_content)
    {
      content: pdf_content[:content] || '',
      page_number: pdf_content[:page_number] || 1,
      chunk_index: pdf_content[:chunk_index] || 1,
      total_chunks: pdf_content[:total_chunks] || 1
    }
  end

  def load_assistant(assistant_id)
    Captain::Assistant.find(assistant_id)
  end

  def processing_should_skip?(assistant)
    exceeded = limit_exceeded?(assistant.account)
    Rails.logger.info "Document limit exceeded for account #{assistant.account.id}" if exceeded
    exceeded
  end

  def load_document(document_id)
    return nil if document_id.blank?

    Captain::Document.find(document_id)
  end

  def log_chunk_processing(document_id, content_data)
    Rails.logger.info "Processing PDF chunk for document #{document_id}: " \
                      "page #{content_data[:page_number]}, " \
                      "chunk #{content_data[:chunk_index]}/#{content_data[:total_chunks]}"
  end

  def update_document_content(document, content_data)
    document.update!(
      content: content_data[:content],
      status: 'available',
      processed_at: Time.current
    )

    # Trigger FAQ generation for this chunk
    Captain::Documents::ResponseBuilderJob.perform_later(document)
  rescue StandardError => e
    Rails.logger.error "Failed to parse PDF content for document #{document.id}: #{e.message}"
    raise "Failed to parse PDF data: #{e.message}"
  end

  def create_new_document(assistant, content_data, document_id = nil)
    document_params = build_document_params(assistant, content_data, document_id)

    new_document = Captain::Document.create!(document_params)

    # Trigger FAQ generation for this chunk
    Captain::Documents::ResponseBuilderJob.perform_later(new_document)

    new_document
  rescue Captain::Document::LimitExceededError
    Rails.logger.info "Document limit exceeded for account #{assistant.account.id}"
    return false
  rescue StandardError => e
    Rails.logger.error "Failed to parse PDF content for assistant #{assistant.id}: #{e.message}"
    raise "Failed to parse PDF data: #{e.message}"
  end

  def build_document_params(assistant, content_data, document_id)
    title = generate_content_title(
      content_data[:content],
      content_data[:page_number],
      content_data[:chunk_index],
      content_data[:total_chunks]
    )

    external_link = generate_external_link(document_id, content_data)

    {
      assistant: assistant,
      account: assistant.account,
      content: content_data[:content],
      name: title,
      external_link: external_link,
      status: 'available',
      source_type: 'pdf_upload',
      content_type: 'application/pdf'
    }
  end

  def generate_external_link(document_id, content_data)
    page_number = content_data[:page_number]
    chunk_index = content_data[:chunk_index]

    if document_id && page_number && chunk_index
      "pdf_chunk_#{document_id}_page_#{page_number}_chunk_#{chunk_index}"
    elsif page_number && chunk_index
      "pdf_chunk_#{SecureRandom.hex(8)}_page_#{page_number}_chunk_#{chunk_index}"
    else
      "pdf_chunk_#{SecureRandom.hex(8)}"
    end
  end

  def generate_content_title(content, page_number, chunk_index, total_chunks)
    return 'PDF Content' if content.blank?

    base_title = extract_base_title(content)
    add_page_chunk_info(base_title, page_number, chunk_index, total_chunks)
  end

  def extract_base_title(content)
    first_line = content.split("\n").first&.strip || ''

    base_title = if first_line.include?('.')
                   extract_sentence_title(first_line)
                 else
                   first_line
                 end

    # Use generic title for long or blank content
    base_title.length > 100 || base_title.blank? ? 'PDF Content' : base_title
  end

  def extract_sentence_title(first_line)
    first_sentence = first_line.split('.').first&.strip || ''
    # Only add period if the original content was actually a complete sentence
    if first_line.split('.').length > 1 && first_line.split('.')[1].strip.present?
      "#{first_sentence}."
    else
      first_sentence
    end
  end

  def add_page_chunk_info(base_title, page_number, chunk_index, total_chunks)
    title_with_info = if total_chunks > 1
                        "#{base_title} (Page #{page_number}, Part #{chunk_index}/#{total_chunks})"
                      elsif page_number && page_number > 1
                        "#{base_title} (Page #{page_number})"
                      else
                        base_title
                      end

    # Ensure title doesn't exceed database limit
    title_with_info.length > 255 ? "#{title_with_info[0, 252]}..." : title_with_info
  end

  def limit_exceeded?(account)
    limits = account.usage_limits.dig(:captain, :documents)
    return false unless limits

    limits[:current_available].to_i <= 0
  end

  def handle_record_not_found_error(error, _document_id)
    Rails.logger.error "Record not found: #{error.message}"
    raise "Failed to parse PDF data: #{error.message}"
  end

  def handle_processing_error(error, assistant_id, document_id)
    Rails.logger.error "Failed to parse PDF content for assistant #{assistant_id}: #{error.message}"

    # If we have a document_id, try to update its status to indicate error
    if document_id.present?
      begin
        document = Captain::Document.find_by(id: document_id)
        # Only update if document exists and update doesn't cause another error
        document&.update(status: 'in_progress') unless error.message.include?('Database error')
      rescue StandardError => e
        Rails.logger.error "Failed to update document status: #{e.message}"
      end
    end

    raise "Failed to parse PDF data: #{error.message}"
  end

  def process_document(assistant, content_data, document_id)
    if document_id.present?
      existing_document = Captain::Document.find_by(id: document_id)
      if existing_document
        log_chunk_processing(document_id, content_data)
        update_document_content(existing_document, content_data)
      else
        result = create_new_document(assistant, content_data, document_id)
        return false if result == false  # Limits exceeded
      end
    else
      result = create_new_document(assistant, content_data, document_id)
      return false if result == false  # Limits exceeded
    end
  end
end