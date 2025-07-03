class Captain::Tools::PdfExtractionParserJob < ApplicationJob
  queue_as :low

  def perform(assistant_id:, pdf_content:, document_id: nil)
    assistant = Captain::Assistant.find(assistant_id)
    main_document = find_main_document(document_id)

    return unless can_process_content?(pdf_content[:content], assistant.account, main_document)

    enqueue_response_builder_job_for_chunk(main_document, pdf_content)
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "PDF parser job failed - Document not found: #{e.message}"
  rescue Captain::Document::LimitExceededError => e
    Rails.logger.info "PDF parser job stopped - Document limit exceeded: #{e.message}"
  end

  private

  def find_main_document(document_id)
    return unless document_id

    Captain::Document.find(document_id)
  end

  def can_process_content?(content, account, main_document)
    main_document && should_process_content?(content, account)
  end

  def enqueue_response_builder_job_for_chunk(main_document, pdf_content)
    # Create a context string for better AI processing that includes page info
    page_info = pdf_content[:page_number] ? " (Page #{pdf_content[:page_number]})" : ''
    chunk_info = pdf_content[:chunk_index] ? " Part #{pdf_content[:chunk_index]}" : ''

    # Combine main document content with chunk content for comprehensive FAQ generation
    context_content = "#{main_document.content}\n\n--- Additional Content#{page_info}#{chunk_info} ---\n#{pdf_content[:content]}"

    # Use the ResponseBuilderJob with full_content parameter to generate FAQs
    # This will link all FAQs to the main document while using the chunk content for AI processing
    # Skip reset since it's already done in the main PDF extraction job
    Captain::Documents::ResponseBuilderJob.perform_later(main_document, context_content)
  end

  def should_process_content?(content, account)
    content.present? && !limit_exceeded?(account)
  end

  def limit_exceeded?(account)
    limits = account.usage_limits.dig(:captain, :documents)
    limits && limits[:current_available].to_i <= 0
  end
end