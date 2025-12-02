class Captain::Llm::ContactAttributesService
  def initialize(assistant, conversation)
    @assistant = assistant
    @conversation = conversation
    @contact = conversation.contact
    @llm = Captain::LlmService.new(api_key: ENV.fetch('OPENAI_API_KEY', nil)) # Or from assistant config
  end

  def generate_and_update_attributes
    extract_attributes
    # TODO: Implement update logic if needed, or return attributes for caller to handle
  end

  private

  def extract_attributes
    messages = [
      { role: 'system', content: Captain::Llm::SystemPromptsService.attributes_generator },
      { role: 'user', content: conversation_context }
    ]

    response = @llm.call(messages, [], json_mode: true)
    parse_result(response[:output])
  rescue StandardError => e
    Rails.logger.error("ContactAttributesService Error: #{e.message}")
    []
  end

  def conversation_context
    <<~TEXT
      # Contact
      #{@contact.try(:to_llm_text) || @contact.name}

      # Conversation
      #{@conversation.try(:to_llm_text) || @conversation.messages.pluck(:content).join("\n")}
    TEXT
  end

  def parse_result(output)
    return [] if output.blank?

    data = JSON.parse(output)
    data['attributes'] || []
  rescue JSON::ParserError
    []
  end
end
