class Captain::Llm::PaginatedFaqGeneratorService < Llm::LegacyBaseOpenAiService
  include Integrations::LlmInstrumentation

  # Default pages per chunk - easily configurable
  DEFAULT_PAGES_PER_CHUNK = 10
  MAX_ITERATIONS = 20 # Safety limit to prevent infinite loops

  attr_reader :total_pages_processed, :iterations_completed

  def initialize(document, options = {})
    super()
    @document = document
    @language = options[:language] || 'english'
    @pages_per_chunk = options[:pages_per_chunk] || DEFAULT_PAGES_PER_CHUNK
    @max_pages = options[:max_pages] # Optional limit from UI
    @total_pages_processed = 0
    @iterations_completed = 0
    @model = LlmConstants::PDF_PROCESSING_MODEL
    @pdf_pages = []
    @total_pages = 0
  end

  def generate
    validate_pdf_presence!
    load_pdf_pages

    generate_paginated_faqs
  end

  # Method to check if we should continue processing
  def should_continue_processing?(last_chunk_result)
    # Stop if we've hit the maximum iterations
    return false if @iterations_completed >= MAX_ITERATIONS

    # Stop if we've processed the maximum pages specified
    return false if @max_pages && @total_pages_processed >= @max_pages

    # Stop if we've reached the end of available PDF pages
    return false if @total_pages.positive? && @total_pages_processed >= @total_pages

    # Stop if the last chunk returned no FAQs (likely no more content)
    return false if last_chunk_result[:faqs].empty?

    # Stop if the LLM explicitly indicates no more content
    return false if last_chunk_result[:has_content] == false

    # Continue processing
    true
  end

  private

  def generate_standard_faqs
    params = standard_chat_parameters
    instrumentation_params = {
      span_name: 'llm.faq_generation',
      account_id: @document&.account_id,
      feature_name: 'faq_generation',
      model: @model,
      messages: params[:messages]
    }

    response = instrument_llm_call(instrumentation_params) do
      @client.chat(parameters: params)
    end

    parse_response(response)
  rescue OpenAI::Error => e
    Rails.logger.error I18n.t('captain.documents.openai_api_error', error: e.message)
    []
  end

  def generate_paginated_faqs
    all_faqs = []
    current_page = 1

    loop do
      break if @total_pages.positive? && current_page > @total_pages

      end_page = calculate_end_page(current_page)
      chunk_text = chunk_text_for(current_page, end_page)
      chunk_result = process_chunk_and_update_state(current_page, end_page, all_faqs, chunk_text)

      break unless should_continue_processing?(chunk_result)

      current_page = end_page + 1
    end

    deduplicate_faqs(all_faqs)
  end

  def calculate_end_page(current_page)
    end_page = current_page + @pages_per_chunk - 1
    end_page = @max_pages if @max_pages && end_page > @max_pages
    end_page = @total_pages if @total_pages.positive? && end_page > @total_pages
    end_page
  end

  def process_chunk_and_update_state(current_page, end_page, all_faqs, chunk_text)
    chunk_result = process_page_chunk(current_page, end_page, chunk_text)
    chunk_faqs = chunk_result[:faqs]

    all_faqs.concat(chunk_faqs)
    @total_pages_processed = [end_page, @total_pages].reject(&:zero?).min || end_page
    @iterations_completed += 1

    chunk_result
  end

  def process_page_chunk(start_page, end_page, chunk_text)
    return { faqs: [], has_content: false } if chunk_text.blank?

    params = build_chunk_parameters(start_page, end_page, chunk_text)

    instrumentation_params = build_instrumentation_params(params, start_page, end_page)

    response = instrument_llm_call(instrumentation_params) do
      @client.chat(parameters: params)
    end

    result = parse_chunk_response(response)
    { faqs: result['faqs'] || [], has_content: result['has_content'] != false }
  rescue OpenAI::Error => e
    Rails.logger.error I18n.t('captain.documents.page_processing_error', start: start_page, end: end_page, error: e.message)
    { faqs: [], has_content: false }
  end

  def build_chunk_parameters(start_page, end_page, chunk_text)
    {
      model: @model,
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content: page_chunk_prompt(start_page, end_page)
        },
        {
          role: 'user',
          content: build_user_content(chunk_text, start_page, end_page)
        }
      ]
    }
  end

  def build_user_content(chunk_text, start_page, end_page)
    [
      {
        type: 'text',
        text: "Content from pages #{start_page}-#{end_page}:\n\n#{chunk_text}"
      }
    ]
  end

  def page_chunk_prompt(start_page, end_page)
    Captain::Llm::SystemPromptsService.paginated_faq_generator(start_page, end_page, @language)
  end

  def standard_chat_parameters
    {
      model: @model,
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content: Captain::Llm::SystemPromptsService.faq_generator(@language)
        },
        {
          role: 'user',
          content: @content
        }
      ]
    }
  end

  def parse_response(response)
    content = response.dig('choices', 0, 'message', 'content')
    return [] if content.nil?

    JSON.parse(content.strip).fetch('faqs', [])
  rescue JSON::ParserError => e
    Rails.logger.error "Error parsing response: #{e.message}"
    []
  end

  def parse_chunk_response(response)
    content = response.dig('choices', 0, 'message', 'content')
    return { 'faqs' => [], 'has_content' => false } if content.nil?

    JSON.parse(content.strip)
  rescue JSON::ParserError => e
    Rails.logger.error "Error parsing chunk response: #{e.message}"
    { 'faqs' => [], 'has_content' => false }
  end

  def deduplicate_faqs(faqs)
    # Remove exact duplicates
    unique_faqs = faqs.uniq { |faq| faq['question'].downcase.strip }

    # Remove similar questions
    final_faqs = []
    unique_faqs.each do |faq|
      similar_exists = final_faqs.any? do |existing|
        similarity_score(existing['question'], faq['question']) > 0.85
      end

      final_faqs << faq unless similar_exists
    end

    Rails.logger.info "Deduplication: #{faqs.size} → #{final_faqs.size} FAQs"
    final_faqs
  end

  def similarity_score(str1, str2)
    words1 = str1.downcase.split(/\W+/).reject(&:empty?)
    words2 = str2.downcase.split(/\W+/).reject(&:empty?)
    common_words = words1 & words2
    total_words = (words1 + words2).uniq.size
    return 0 if total_words.zero?

    common_words.size.to_f / total_words
  end

  def build_instrumentation_params(params, start_page, end_page)
    {
      span_name: 'llm.paginated_faq_generation',
      account_id: @document&.account_id,
      feature_name: 'paginated_faq_generation',
      model: @model,
      messages: params[:messages],
      metadata: {
        document_id: @document&.id,
        start_page: start_page,
        end_page: end_page,
        iteration: @iterations_completed + 1
      }
    }
  end

  def validate_pdf_presence!
    return if @document&.pdf_file&.attached?

    raise CustomExceptions::Pdf::FaqGenerationError, I18n.t('captain.documents.pdf_file_missing')
  end

  def load_pdf_pages
    return if @pdf_pages.present?

    require_pdf_reader!
    @pdf_pages = extract_pdf_pages
    @total_pages = @pdf_pages.length

    raise CustomExceptions::Pdf::FaqGenerationError, I18n.t('captain.documents.pdf_content_missing') if @total_pages.zero?
  end

  def extract_pdf_pages
    pages = []
    @document.pdf_file.blob.open do |file|
      reader = PDF::Reader.new(file)
      reader.pages.each { |page| pages << page.text }
    end
    pages
  rescue StandardError => e
    Rails.logger.error I18n.t('captain.documents.page_processing_error', start: 0, end: 0, error: e.message)
    []
  end

  def require_pdf_reader!
    require 'pdf-reader'
  rescue LoadError => e
    Rails.logger.error "pdf-reader gem missing: #{e.message}"
    raise CustomExceptions::Pdf::FaqGenerationError, I18n.t('captain.documents.pdf_content_missing')
  end

  def chunk_text_for(start_page, end_page)
    return '' if @pdf_pages.empty?

    slice = @pdf_pages[(start_page - 1)..(end_page - 1)]
    slice = Array(slice).compact
    slice.join("\n\n")
  end
end
