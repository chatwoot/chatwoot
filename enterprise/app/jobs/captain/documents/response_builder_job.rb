class Captain::Documents::ResponseBuilderJob < ApplicationJob
  queue_as :low

  def perform(document, full_content = nil, skip_reset: false, metadata: {})
    # Use full content for FAQ generation if provided (for PDFs), otherwise use document.content
    content_for_faqs = full_content || document.content

    # Skip processing if no content available
    return if content_for_faqs.blank?

    # Only reset responses if not explicitly skipped
    reset_previous_responses(document) unless skip_reset

    # Check if this is a direct PDF processing
    faqs = if metadata[:processing_type] == 'direct_pdf' && metadata[:openai_file_id]
             Captain::Llm::PdfFaqGeneratorService.new(
               content_for_faqs,
               is_pdf_file: true,
               metadata: metadata
             ).generate
           # NOTE: Not deleting the file_id - keeping it for future use
           else
             Captain::Llm::FaqGeneratorService.new(content_for_faqs).generate
           end

    faqs.each do |faq|
      create_response(faq, document)
    end
  end

  private

  def reset_previous_responses(response_document)
    response_document.responses.destroy_all
  end

  def create_response(faq, document)
    document.responses.create!(
      question: faq['question'],
      answer: faq['answer'],
      assistant: document.assistant,
      documentable: document
    )
  rescue ActiveRecord::RecordInvalid => e
    # Log validation errors but continue processing other FAQs
    Rails.logger.info "Skipping duplicate or invalid FAQ: #{e.message}"
  end
end
