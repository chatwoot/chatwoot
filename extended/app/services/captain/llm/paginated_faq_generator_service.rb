class Captain::Llm::PaginatedFaqGeneratorService
  DEFAULT_PAGES_PER_CHUNK = 10
  MAX_ITERATIONS = 20

  attr_reader :total_pages_processed, :iterations_completed

  def initialize(document, options = {})
    @document = document
    @language = options[:language] || 'english'
    @pages_per_chunk = options[:pages_per_chunk] || DEFAULT_PAGES_PER_CHUNK
    @max_pages = options[:max_pages]
    @llm = Captain::LlmService.new(api_key: ENV.fetch('OPENAI_API_KEY', nil))
    @total_pages_processed = 0
    @iterations_completed = 0
  end

  def generate
    raise 'Missing OpenAI File ID' if @document.try(:openai_file_id).blank?

    faqs = process_document
    deduplicate(faqs)
  end

  private

  def process_document
    all_faqs = []
    current_page = 1
    iterations = 0

    loop do
      break if iterations >= MAX_ITERATIONS
      break if @max_pages && current_page > @max_pages

      end_page = calculate_end_page(current_page)
      result = process_chunk(current_page, end_page)

      all_faqs.concat(result[:faqs])

      break unless result[:has_content]
      break if result[:faqs].empty? # Assume empty means end of content

      @total_pages_processed = end_page
      current_page = end_page + 1
      iterations += 1
    end

    @iterations_completed = iterations
    all_faqs
  end

  def calculate_end_page(start_page)
    end_page = start_page + @pages_per_chunk - 1
    @max_pages ? [end_page, @max_pages].min : end_page
  end

  def process_chunk(start_page, end_page)
    messages = [
      {
        role: 'user',
        content: [
          { type: 'file', file: { file_id: @document.openai_file_id } },
          { type: 'text', text: Captain::Llm::SystemPromptsService.paginated_faq_generator(start_page, end_page, @language) }
        ]
      }
    ]

    # Using a specific model that supports file search if needed, or default
    # Assuming the LLM service handles the model selection or we pass it
    response = @llm.call(messages, [], json_mode: true)

    parse_chunk_result(response[:output])
  rescue StandardError => e
    Rails.logger.error("PaginatedFaqGeneratorService Error: #{e.message}")
    { faqs: [], has_content: false }
  end

  def parse_chunk_result(output)
    return { faqs: [], has_content: false } if output.blank?

    data = JSON.parse(output)
    {
      faqs: data['faqs'] || [],
      has_content: data['has_content']
    }
  rescue JSON::ParserError
    { faqs: [], has_content: false }
  end

  def deduplicate(faqs)
    # Simple deduplication based on question text
    faqs.uniq { |f| f['question'].to_s.downcase.strip }
  end
end
