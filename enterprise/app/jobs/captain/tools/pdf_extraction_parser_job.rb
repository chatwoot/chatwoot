class Captain::Tools::PdfExtractionParserJob < ApplicationJob
  queue_as :low

  def perform(assistant_id:, pdf_content:, document_id: nil)
    assistant = Captain::Assistant.find(assistant_id)
    content = pdf_content[:content]

    return if content.blank? || limit_exceeded?(assistant.account)

    document = create_document(assistant, pdf_content, document_id)
    Captain::Documents::ResponseBuilderJob.perform_later(document) if document
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "PDF parser job failed - Assistant not found: #{e.message}"
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "PDF parser job failed - Invalid document data: #{e.message}"
  rescue Captain::Document::LimitExceededError => e
    Rails.logger.info "PDF parser job stopped - Document limit exceeded: #{e.message}"
  end

  private

  def create_document(assistant, pdf_content, document_id)
    Captain::Document.create!(
      assistant: assistant,
      account: assistant.account,
      content: pdf_content[:content],
      name: generate_title(pdf_content),
      external_link: generate_link(document_id, pdf_content),
      status: 'available',
      source_type: 'pdf_upload'
    )
  rescue Captain::Document::LimitExceededError
    Rails.logger.info "Document limit exceeded for account #{assistant.account.id}"
    nil
  end

  def generate_title(pdf_content)
    base_title = extract_base_title(pdf_content[:content])
    title_with_page_info = add_page_information(base_title, pdf_content)
    title_with_page_info.truncate(255)
  end

  def extract_base_title(content)
    first_line = content.split("\n").first&.strip || ''
    return 'PDF Content' if first_line.length > 50 || first_line.blank?

    first_line
  end

  def add_page_information(base_title, pdf_content)
    page = pdf_content[:page_number]
    chunk = pdf_content[:chunk_index]
    total = pdf_content[:total_chunks]

    return "#{base_title} (Page #{page}, Part #{chunk}/#{total})" if total && total > 1
    return "#{base_title} (Page #{page})" if page && page > 1

    base_title
  end

  def generate_link(document_id, pdf_content)
    page = pdf_content[:page_number]
    chunk = pdf_content[:chunk_index]

    if document_id
      "pdf_chunk_#{document_id}_page_#{page}_chunk_#{chunk}"
    else
      "pdf_chunk_#{SecureRandom.hex(8)}_page_#{page}_chunk_#{chunk}"
    end
  end

  def limit_exceeded?(account)
    limits = account.usage_limits.dig(:captain, :documents)
    limits && limits[:current_available].to_i <= 0
  end
end