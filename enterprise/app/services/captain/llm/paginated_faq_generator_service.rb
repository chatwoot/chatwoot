class Captain::Llm::PaginatedFaqGeneratorService < Llm::BaseOpenAiService
  # Default pages per chunk - easily configurable
  DEFAULT_PAGES_PER_CHUNK = 10
  MAX_ITERATIONS = 20 # Safety limit to prevent infinite loops

  attr_reader :total_pages_processed, :iterations_completed

  def initialize(document, options = {})
    super()
    @document = document
    @pages_per_chunk = options[:pages_per_chunk] || DEFAULT_PAGES_PER_CHUNK
    @max_pages = options[:max_pages] # Optional limit from UI
    @total_pages_processed = 0
    @iterations_completed = 0
    @model = OpenAiConstants::PDF_PROCESSING_MODEL
  end

  def generate
    raise CustomExceptions::PdfFaqGenerationError, I18n.t('captain.documents.missing_openai_file_id') if @document&.openai_file_id.blank?

    generate_paginated_faqs
  end

  # Method to check if we should continue processing
  def should_continue_processing?(last_chunk_result)
    # Stop if we've hit the maximum iterations
    return false if @iterations_completed >= MAX_ITERATIONS

    # Stop if we've processed the maximum pages specified
    return false if @max_pages && @total_pages_processed >= @max_pages

    # Stop if the last chunk returned no FAQs (likely no more content)
    return false if last_chunk_result[:faqs].empty?

    # Stop if the LLM explicitly indicates no more content
    return false if last_chunk_result[:has_content] == false

    # Continue processing
    true
  end

  private

  def generate_standard_faqs
    response = @client.chat(parameters: standard_chat_parameters)
    parse_response(response)
  rescue OpenAI::Error => e
    Rails.logger.error I18n.t('captain.documents.openai_api_error', error: e.message)
    []
  end

  def generate_paginated_faqs
    all_faqs = []
    current_page = 1

    loop do
      end_page = calculate_end_page(current_page)
      chunk_result = process_chunk_and_update_state(current_page, end_page, all_faqs)

      break unless should_continue_processing?(chunk_result)

      current_page = end_page + 1
    end

    deduplicate_faqs(all_faqs)
  end

  def calculate_end_page(current_page)
    end_page = current_page + @pages_per_chunk - 1
    @max_pages && end_page > @max_pages ? @max_pages : end_page
  end

  def process_chunk_and_update_state(current_page, end_page, all_faqs)
    chunk_result = process_page_chunk(current_page, end_page)
    chunk_faqs = chunk_result[:faqs]

    all_faqs.concat(chunk_faqs)
    @total_pages_processed = end_page
    @iterations_completed += 1

    chunk_result
  end

  def process_page_chunk(start_page, end_page)
    params = build_chunk_parameters(start_page, end_page)
    response = @client.chat(parameters: params)
    result = parse_chunk_response(response)
    { faqs: result['faqs'] || [], has_content: result['has_content'] != false }
  rescue OpenAI::Error => e
    Rails.logger.error I18n.t('captain.documents.page_processing_error', start: start_page, end: end_page, error: e.message)
    { faqs: [], has_content: false }
  end

  def build_chunk_parameters(start_page, end_page)
    {
      model: @model,
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'user',
          content: build_user_content(start_page, end_page)
        }
      ]
    }
  end

  def build_user_content(start_page, end_page)
    [
      {
        type: 'file',
        file: { file_id: @document.openai_file_id }
      },
      {
        type: 'text',
        text: page_chunk_prompt(start_page, end_page)
      }
    ]
  end

  def page_chunk_prompt(start_page, end_page)
    Captain::Llm::SystemPromptsService.paginated_faq_generator(start_page, end_page)
  end

  def standard_chat_parameters
    {
      model: @model,
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content: Captain::Llm::SystemPromptsService.faq_generator
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

  def determine_stop_reason(last_chunk_result)
    return 'Maximum iterations reached' if @iterations_completed >= MAX_ITERATIONS
    return 'Maximum pages processed' if @max_pages && @total_pages_processed >= @max_pages
    return 'No content found in last chunk' if last_chunk_result[:faqs].empty?
    return 'End of document reached' if last_chunk_result[:has_content] == false

    'Unknown'
  end
end
