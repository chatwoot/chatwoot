class Captain::Llm::FaqGeneratorService < Llm::BaseOpenAiService
  def initialize(content)
    super()
    @content = content
  end

  def generate
    response = @client.chat(parameters: chat_parameters)
    parse_response(response)
  rescue OpenAI::Error => e
    Rails.logger.error "OpenAI API Error: #{e.message}"
    []
  end

  private

  attr_reader :content

  def chat_parameters
    prompt = Captain::Llm::SystemPromptsService.faq_generator
    {
      model: @model,
      # response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content: "#{prompt}\n\nPlease respond with a JSON object containing an array of FAQs in the format: {\"faqs\": [{\"question\": \"...\", \"answer\": \"...\"}]}"
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

    # Try to extract JSON from the response
    json_match = content.match(/\{.*\}/m)
    return [] unless json_match

    JSON.parse(json_match[0]).fetch('faqs', [])
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response: #{e.message}"
    []
  end
end
