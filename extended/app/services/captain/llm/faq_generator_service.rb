class Captain::Llm::FaqGeneratorService < Llm::BaseService
  def initialize(content, language = 'english')
    super()
    @language = language
    @content = content
  end

  def generate
    response = @provider.chat(parameters: chat_parameters)
    parse_response(response)
  rescue StandardError => e
    Rails.logger.error "LLM API Error: #{e.message}"
    []
  end

  private

  attr_reader :content, :language

  def chat_parameters
    prompt = Captain::Llm::SystemPromptsService.faq_generator(language)
    {
      model: Captain::Config.config_for(Captain::Config.current_provider)[:chat_model],
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content: prompt
        },
        {
          role: 'user',
          content: content
        }
      ]
    }
  end

  def parse_response(response)
    content = response.dig('choices', 0, 'message', 'content')
    return [] if content.nil?

    JSON.parse(content.strip).fetch('faqs', [])
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response: #{e.message}"
    []
  end
end
