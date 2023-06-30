class Integrations::OpenaiProcessorService
  # 3.5 support 4,096 tokens
  # 1 token is approx 4 characters
  # 4,096 * 4 = 16,384 characters, sticking to 15,000 to be safe
  TOKEN_LIMIT = 15_000
  API_URL = 'https://api.openai.com/v1/chat/completions'.freeze
  GPT_MODEL = 'gpt-3.5-turbo'.freeze

  ALLOWED_EVENT_NAMES = %w[rephrase summarize reply_suggestion suggest_label].freeze
  CACHEABLE_EVENTS = %w[suggest_label].freeze

  pattr_initialize [:hook!, :event!]

  def perform
    event_name = event['name']
    return nil unless valid_event_name?(event_name)

    return value_from_cache if CACHEABLE_EVENTS.include?(event_name) && value_from_cache.present?

    response = send("#{event_name}_message")
    save_to_cache(response) if CACHEABLE_EVENTS.include?(event_name) && response.present?

    response
  end

  private

  def cache_key
    conversation = find_conversation
    return nil unless conversation

    format(::Redis::Alfred::OPENAI_CONVERSATION_KEY, event_name: event['name'], conversation_id: conversation.id,
                                                     updated_at: conversation.last_activity_at.to_i)
  end

  def value_from_cache
    # since the value from cache depends on the conversation last_activity_at, it will always be fresh
    return nil if cache_key.blank?

    Redis::Alfred.get(cache_key)
  end

  def save_to_cache(response)
    Redis::Alfred.setex(cache_key, response)
  end

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
