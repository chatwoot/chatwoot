class Captain::Llm::ContactAttributesService < Llm::BaseOpenAiService
  def initialize(assistant, conversation)
    super()
    @assistant = assistant
    @conversation = conversation
    @contact = conversation.contact
    @content = "#Contact\n\n#{@contact.to_llm_text} \n\n#Conversation\n\n#{@conversation.to_llm_text}"
  end

  def generate_and_update_attributes
    generate_attributes
    # to implement the update attributes
  end

  private

  attr_reader :content

  def generate_attributes
    response = @client.chat(parameters: chat_parameters)
    parse_response(response)
  rescue OpenAI::Error => e
    Rails.logger.error "OpenAI API Error: #{e.message}"
    []
  end

  def chat_parameters
    prompt = Captain::Llm::SystemPromptsService.attributes_generator
    {
      model: @model,
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

    JSON.parse(content.strip).fetch('attributes', [])
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response: #{e.message}"
    []
  end
end
