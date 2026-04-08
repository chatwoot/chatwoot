class Captain::Documents::ResponseBuilderJob < ApplicationJob
  queue_as :low

  def perform(document, options = {})
    document.merge_faq_generation_metadata!(
      'status' => Captain::Document::FAQ_GENERATION_STATUS_PROCESSING,
      'updated_at' => Time.current.iso8601
    )

    reset_previous_responses(document)

    faqs = generate_faqs(document, options)
    create_responses_from_faqs(faqs, document)
    finalize_faq_generation!(document, faqs)
  rescue StandardError => e
    document.merge_faq_generation_metadata!(
      'status' => Captain::Document::FAQ_GENERATION_STATUS_FAILED,
      'error' => e.message.to_s.truncate(500),
      'updated_at' => Time.current.iso8601
    )
    raise e
  end

  private

  def finalize_faq_generation!(document, faqs)
    attrs = {
      'status' => Captain::Document::FAQ_GENERATION_STATUS_COMPLETED,
      'responses_count' => faqs.size,
      'updated_at' => Time.current.iso8601
    }
    attrs['method'] = 'standard' unless should_use_pagination?(document)
    document.merge_faq_generation_metadata!(attrs)
  end

  def generate_faqs(document, options)
    if should_use_pagination?(document)
      generate_paginated_faqs(document, options)
    else
      generate_standard_faqs(document)
    end
  end

  def generate_paginated_faqs(document, options)
    service = build_paginated_service(document, options)
    faqs = service.generate
    store_paginated_metadata(document, service)
    faqs
  end

  def generate_standard_faqs(document)
    Captain::Llm::FaqGeneratorService.new(document.content, document.account.locale_english_name, account_id: document.account_id).generate
  end

  def build_paginated_service(document, options)
    Captain::Llm::PaginatedFaqGeneratorService.new(
      document,
      pages_per_chunk: options[:pages_per_chunk],
      max_pages: options[:max_pages],
      language: document.account.locale_english_name
    )
  end

  def store_paginated_metadata(document, service)
    document.merge_faq_generation_metadata!(
      'method' => 'paginated',
      'pages_processed' => service.total_pages_processed,
      'iterations' => service.iterations_completed,
      'timestamp' => Time.current.iso8601
    )
  end

  def create_responses_from_faqs(faqs, document)
    faqs.each { |faq| create_response(faq, document) }
  end

  def should_use_pagination?(document)
    # Auto-detect when to use pagination
    # Use pagination for PDF documents with an attached file
    document.pdf_document? && document.pdf_file.attached?
  end

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
    Rails.logger.error I18n.t('captain.documents.response_creation_error', error: e.message)
  end
end
