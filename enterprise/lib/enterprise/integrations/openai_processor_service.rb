module Enterprise::Integrations::OpenaiProcessorService
  ALLOWED_EVENT_NAMES = %w[rephrase summarize reply_suggestion label_suggestion fix_spelling_grammar shorten expand
                           make_friendly make_formal simplify].freeze
  CACHEABLE_EVENTS = %w[label_suggestion].freeze

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
    conversation = find_conversation

    # return nil if conversation is not present
    return nil if conversation.nil?

    # return nil if conversation has less than 3 incoming messages
    return nil if conversation.messages.incoming.count < 3

    labels = hook.account.labels.pluck(:title).join(', ')
    character_count = labels.length

    messages = init_messages_body(false)
    add_messages_until_token_limit(conversation, messages, false, character_count)

    return nil if messages.blank? || labels.blank?

    "Messages:\n#{messages}\nLabels:\n#{labels}"
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
    content = labels_with_messages
    return nil if content.blank?

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
end
