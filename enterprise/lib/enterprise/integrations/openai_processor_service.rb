module Enterprise::Integrations::OpenaiProcessorService
  ALLOWED_EVENT_NAMES = %w[rephrase summarize reply_suggestion label_suggestion].freeze
  CACHEABLE_EVENTS = %w[label_suggestion].freeze

  def label_suggestion_message
    payload = label_suggestion_body
    return nil if payload.blank?

    response = make_api_call(label_suggestion_body)

    # LLMs are not deterministic, so this is bandaid solution
    # To what you ask? Sometimes, the response includes
    # "Labels:" in it's response in some format. This is a hacky way to remove it
    # TODO: Fix with with a better prompt
    response.gsub(/^(label|labels):/i, '')
  end

  private

  def labels_with_messages
    labels = hook.account.labels.pluck(:title).join(', ')

    character_count = labels.length
    conversation = find_conversation
    messages = init_messages_body(false)
    add_messages_until_token_limit(conversation, messages, false, character_count)

    return nil if messages.blank? || labels.blank?

    "Messages:\n#{messages}\nLabels:\n#{labels}"
  end

  def label_suggestion_body
    content = labels_with_messages
    return nil if content.blank?

    {
      model: self.class::GPT_MODEL,
      messages: [
        {
          role: 'system',
          content: 'Your role is as an assistant to a customer support agent. You will be provided with a transcript of a conversation between a ' \
                   'customer and the support agent, along with a list of potential labels. ' \
                   'Your task is to analyze the conversation and select the two labels from the given list that most accurately ' \
                   'represent the themes or issues discussed. Ensure you preserve the exact casing of the labels as they are provided in the list. ' \
                   'Do not create new labels; only choose from those provided. Once you have made your selections, please provide your response ' \
                   'as a comma-separated list of the provided labels. Remember, your response should only contain the labels you\'ve selected, ' \
                   'in their original casing, and nothing else. '
        },
        { role: 'user', content: content }
      ]
    }.to_json
  end
end
