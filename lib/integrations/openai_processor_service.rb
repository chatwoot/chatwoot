class Integrations::OpenaiProcessorService
  TOKEN_LIMIT = 15_000
  API_URL = 'https://api.openai.com/v1/chat/completions'.freeze
  GPT_MODEL = 'gpt-3.5-turbo'.freeze

  ALLOWED_EVENT_NAMES = %w[rephrase summarize reply_suggestion suggest_label].freeze

  pattr_initialize [:hook!, :event!]

  def perform
    event_name = event['name']
    return nil unless valid_event_name?(event_name)

    send("#{event_name}_message")
  end

  private

  def find_conversation
    hook.account.conversations.find_by(display_id: event['data']['conversation_display_id'])
  end

  def valid_event_name?(event_name)
    ALLOWED_EVENT_NAMES.include?(event_name)
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
