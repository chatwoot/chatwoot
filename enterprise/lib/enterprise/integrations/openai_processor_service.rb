module Enterprise::Integrations::OpenaiProcessorService
  ALLOWED_EVENT_NAMES = %w[rephrase summarize reply_suggestion label_suggestion fix_spelling_grammar shorten expand
                           make_friendly make_formal simplify].freeze
  CACHEABLE_EVENTS = %w[label_suggestion].freeze

  def reply_suggestion_message
    return super unless conversation.inbox.response_bot_enabled?

    messages = conversation_messages(in_array_format: true)
    last_message = messages.pop

    robin_response = ChatGpt.new(
      Enterprise::MessageTemplates::ResponseBotService.response_sections(last_message[:content], conversation.inbox)
    ).generate_response(
      last_message[:content], messages, last_message[:role]
    )
    message_content = robin_response['response']
    if robin_response['context_ids'].present?
      message_content += Enterprise::MessageTemplates::ResponseBotService.generate_sources_section(robin_response['context_ids'])
    end
    message_content
  end

  def label_suggestion_message
    payload = label_suggestion_body
    return nil if payload.blank?

    response = make_api_call(label_suggestion_body)

    # LLMs are not deterministic, so this is bandaid solution
    # To what you ask? Sometimes, the response includes
    # "Labels:" in it's response in some format. This is a hacky way to remove it
    # TODO: Fix with with a better prompt
    response.present? ? response.gsub(/^(label|labels):/i, '') : ''
  end

  private

  def labels_with_messages
    return nil unless valid_conversation?(conversation)

    labels = hook.account.labels.pluck(:title).join(', ')
    character_count = labels.length

    messages = init_messages_body(false)
    add_messages_until_token_limit(conversation, messages, false, character_count)

    return nil if messages.blank? || labels.blank?

    "Messages:\n#{messages}\nLabels:\n#{labels}"
  end

  def valid_conversation?(conversation)
    return false if conversation.nil?
    return false if conversation.messages.incoming.count < 3

    # Think Mark think, at this point the conversation is beyond saving
    return false if conversation.messages.count > 100

    # if there are more than 20 messages, only trigger this if the last message is from the client
    return false if conversation.messages.count > 20 && !conversation.messages.last.incoming?

    true
  end

  def summarize_body
    {
      model: self.class::GPT_MODEL,
      messages: [
        { role: 'system',
          content: prompt_from_file('summary', enterprise: true) },
        { role: 'user', content: conversation_messages }
      ]
    }.to_json
  end

  def label_suggestion_body
    return unless label_suggestions_enabled?

    content = labels_with_messages
    return value_from_cache if content.blank?

    {
      model: self.class::GPT_MODEL,
      messages: [
        {
          role: 'system',
          content: prompt_from_file('label_suggestion', enterprise: true)
        },
        { role: 'user', content: content }
      ]
    }.to_json
  end

  def label_suggestions_enabled?
    hook.settings['label_suggestion'].present?
  end
end
