class Captain::Llm::ContactNotesService
  def initialize(assistant, conversation)
    @assistant = assistant
    @conversation = conversation
    @contact = conversation.contact
    @llm = Captain::LlmService.new(api_key: ENV.fetch('OPENAI_API_KEY', nil)) # Or from assistant config
  end

  def generate_and_update_notes
    notes = extract_notes
    notes.each do |note|
      @contact.notes.create!(content: note)
    end
  end

  private

  def extract_notes
    language = @conversation.account.locale_english_name
    messages = [
      { role: 'system', content: Captain::Llm::SystemPromptsService.notes_generator(language) },
      { role: 'user', content: conversation_context }
    ]

    response = @llm.call(messages, [], json_mode: true)
    parse_result(response[:output])
  rescue StandardError => e
    Rails.logger.error("ContactNotesService Error: #{e.message}")
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
    data['notes'] || []
  rescue JSON::ParserError
    []
  end
end
