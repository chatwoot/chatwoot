class Captain::Llm::ContactNotesService < Llm::BaseOpenAiService
  def initialize(assistant, conversation)
    super()
    @assistant = assistant
    @conversation = conversation
    @contact = conversation.contact
    @content = "#Contact\n\n#{@contact.to_llm_text} \n\n#Conversation\n\n#{@conversation.to_llm_text}"
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
    account_language = @conversation.account.locale_english_name
    prompt = Captain::Llm::SystemPromptsService.notes_generator(account_language)

    {
      model: @model,
      # response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content: "#{prompt}\n\nPlease respond with a JSON object containing an array of notes in the format: {\"notes\": [\"note1\", \"note2\", ...]}"
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

    JSON.parse(json_match[0]).fetch('notes', [])
  rescue JSON::ParserError => e
    Rails.logger.error "Error in parsing GPT processed response: #{e.message}"
    []
  end
end
