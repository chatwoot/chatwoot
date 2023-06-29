class Integrations::Openai::ProcessorService < Integrations::OpenaiProcessorService
  def reply_suggestion_message
    make_api_call(reply_suggestion_body)
  end

  def summarize_message
    make_api_call(summarize_body)
  end

  def rephrase_message
    make_api_call(rephrase_body)
  end

  def suggest_label_message
    make_api_call(suggest_label_body)
  end

  private

  def rephrase_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'system',
          content: "You are a helpful support agent. Please rephrase the following response to a more #{event['data']['tone']} tone. " \
                   "Reply in the user's language." },
        { role: 'user', content: event['data']['content'] }
      ]
    }.to_json
  end

  def conversation_messages(in_array_format: false)
    conversation = find_conversation
    messages = init_messages_body(in_array_format)

    add_messages_until_token_limit(conversation, messages, in_array_format)
  end

  def labels_with_messages
    labels = hook.account.labels.pluck(:title).join(', ')

    character_count = labels.length
    conversation = find_conversation
    messages = init_messages_body(false)
    add_messages_until_token_limit(conversation, messages, false, character_count)

    "Messages:\n#{messages}\nLabels:\n#{labels}"
  end

  def add_messages_until_token_limit(conversation, messages, in_array_format, start_from = 0)
    character_count = start_from
    conversation.messages.chat.reorder('id desc').each do |message|
      character_count, message_added = add_message_if_within_limit(character_count, message, messages, in_array_format)
      break unless message_added
    end
    messages
  end

  def add_message_if_within_limit(character_count, message, messages, in_array_format)
    if valid_message?(message, character_count)
      add_message_to_list(message, messages, in_array_format)
      character_count += message.content.length
      [character_count, true]
    else
      [character_count, false]
    end
  end

  def valid_message?(message, character_count)
    message.content.present? && character_count + message.content.length <= TOKEN_LIMIT
  end

  def add_message_to_list(message, messages, in_array_format)
    formatted_message = format_message(message, in_array_format)
    messages.prepend(formatted_message)
  end

  def init_messages_body(in_array_format)
    in_array_format ? [] : ''
  end

  def format_message(message, in_array_format)
    in_array_format ? format_message_in_array(message) : format_message_in_string(message)
  end

  def format_message_in_array(message)
    { role: (message.incoming? ? 'user' : 'assistant'), content: message.content }
  end

  def format_message_in_string(message)
    sender_type = message.incoming? ? 'Customer' : 'Agent'
    "#{sender_type} #{message.sender&.name} : #{message.content}\n"
  end

  def summarize_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'system',
          content: 'Please summarize the key points from the following conversation between support agents and ' \
                   'customer as bullet points for the next support agent looking into the conversation. Reply in the user\'s language.' },
        { role: 'user', content: conversation_messages }
      ]
    }.to_json
  end

  def reply_suggestion_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'system',
          content: 'Please suggest a reply to the following conversation between support agents and customer. Reply in the user\'s language.' }
      ].concat(conversation_messages(in_array_format: true))
    }.to_json
  end

  def suggest_label_body
    {
      model: GPT_MODEL,
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
        {
          role: 'user', content: labels_with_messages
        }
      ]
    }.to_json
  end
end
