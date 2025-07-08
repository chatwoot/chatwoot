class Captain::Documents::ResponseBuilderJob < ApplicationJob
  queue_as :low

  def perform(document, full_content = nil, skip_reset: false)
    # Use full content for FAQ generation if provided (for PDFs), otherwise use document.content
    content_for_faqs = full_content || document.content

    # Skip processing if no content available
    return if content_for_faqs.blank?

    # Only reset responses if not explicitly skipped (for PDF chunks processing)
    reset_previous_responses(document) unless skip_reset

    faqs = Captain::Llm::FaqGeneratorService.new(content_for_faqs).generate
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
