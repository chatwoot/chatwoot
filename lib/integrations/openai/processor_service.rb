class Integrations::Openai::ProcessorService
  # 3.5 support 4,096 tokens
  # 1 token is approx 4 characters
  # 4,096 * 4 = 16,384 characters, sticking to 15,000 to be safe
  TOKEN_LIMIT = 15_000
  API_URL = 'https://api.openai.com/v1/chat/completions'.freeze
  GPT_MODEL = 'gpt-3.5-turbo'.freeze

  ALLOWED_EVENT_NAMES = %w[rephrase summarize reply_suggestion].freeze

  pattr_initialize [:hook!, :event!]

  def perform
    event_name = event['name']
    return nil unless valid_event_name?(event_name)

    send("#{event_name}_message")
  end

  private

  def valid_event_name?(event_name)
    ALLOWED_EVENT_NAMES.include?(event_name)
  end

  def rephrase_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'system',
          content: "You are a helpful support agent. Please rephrase the following response to a more #{event['data']['tone']} tone." },
        { role: 'user', content: event['data']['content'] }
      ]
    }.to_json
  end

  def conversation_messages(in_array_format: false)
    conversation = hook.account.conversations.find_by(display_id: event['data']['conversation_display_id'])
    messages = in_array_format ? [] : ''
    character_count = 0

    conversation.messages.chat.reorder('id desc').each do |message|
      character_count += message.content.length
      break if character_count > TOKEN_LIMIT

      formatted_message = format_message(message, in_array_format)
      messages.prepend(formatted_message)
    end
    messages
  end

  def format_message(message, in_array_format)
    if in_array_format
      { role: (message.incoming? ? 'user' : 'assistant'), content: message.content }
    else
      sender_type = message.incoming? ? 'Customer' : 'Agent'
      "#{sender_type} #{message.sender&.name} : #{message.content}\n"
    end
  end

  def summarize_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'system',
          content: 'Please summarize the key points from the following conversation between support agents and customer as bullet points
           for the next support agent looking into the conversation' },
        { role: 'user', content: conversation_messages }
      ]
    }.to_json
  end

  def reply_suggestion_body
    {
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: 'Please suggest a reply to the following conversation between support agents and customer' }
      ].concat(conversation_messages(in_array_format: true))
    }.to_json
  end

  def reply_suggestion_message
    make_api_call(reply_suggestion_body)
  end

  def summarize_message
    make_api_call(summarize_body)
  end

  def rephrase_message
    make_api_call(rephrase_body)
  end

  def make_api_call(body)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{hook.settings['api_key']}"
    }

    response = HTTParty.post(API_URL, headers: headers, body: body)
    JSON.parse(response.body)['choices'].first['message']['content']
  end
end
