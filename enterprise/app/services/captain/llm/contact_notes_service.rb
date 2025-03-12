class Captain::Llm::ContactNotesService < Captain::Llm::BaseOpenAiService
  DEFAULT_MODEL = 'gpt-4o'.freeze

  def initialize(assistant, conversation, model = DEFAULT_MODEL)
    super()
    @assistant = assistant
    @conversation = conversation
    @contact = conversation.contact
    @content = "#Contact\n\n#{@contact.to_llm_text} \n\n#Conversation\n\n#{@conversation.to_llm_text}"
    @model = model
  end

  def generate_and_update_notes
    generate_notes.each do |note|
      @contact.notes.create!(content: note)
    end
  end

  private

  attr_reader :content

  def generate_notes
    response = @client.chat(parameters: chat_parameters)
    parse_response(response)
  rescue OpenAI::Error => e
    Rails.logger.error "OpenAI API Error: #{e.message}"
    []
  end

  def chat_parameters
    prompt = Captain::Llm::SystemPromptsService.notes_generator
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

    JSON.parse(content.strip).fetch('notes', [])
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response: #{e.message}"
    []
  end
end
