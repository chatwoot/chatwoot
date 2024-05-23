class Integrations::OpenaiBaseService
  # 3.5 support 16,385 tokens
  # 1 token is approx 4 characters
  # 16385 * 4 = 65540 characters, sticking to 50,000 to be safe
  TOKEN_LIMIT = 50_000
  API_URL = 'https://api.openai.com/v1/chat/completions'.freeze
  GPT_MODEL = 'gpt-3.5-turbo'.freeze

  ALLOWED_EVENT_NAMES = %w[rephrase summarize reply_suggestion fix_spelling_grammar shorten expand make_friendly make_formal simplify].freeze
  CACHEABLE_EVENTS = %w[].freeze

  pattr_initialize [:hook!, :event!]

  def perform
    return nil unless valid_event_name?

    return value_from_cache if value_from_cache.present?

    response = send("#{event_name}_message")
    save_to_cache(response) if response.present?

    response
  end

  private

  def event_name
    event['name']
  end

  def cache_key
    return nil unless event_is_cacheable?

    return nil unless conversation

    # since the value from cache depends on the conversation last_activity_at, it will always be fresh
    format(::Redis::Alfred::OPENAI_CONVERSATION_KEY, event_name: event_name, conversation_id: conversation.id,
                                                     updated_at: conversation.last_activity_at.to_i)
  end

  def value_from_cache
    return nil unless event_is_cacheable?
    return nil if cache_key.blank?

    Redis::Alfred.get(cache_key)
  end

  def save_to_cache(response)
    return nil unless event_is_cacheable?

    Redis::Alfred.setex(cache_key, response)
  end

  def conversation
    @conversation ||= hook.account.conversations.find_by(display_id: event['data']['conversation_display_id'])
  end

  def valid_event_name?
    # self.class::ALLOWED_EVENT_NAMES is way to access ALLOWED_EVENT_NAMES defined in the class hierarchy of the current object.
    # This ensures that if ALLOWED_EVENT_NAMES is updated elsewhere in it's ancestors, we access the latest value.
    self.class::ALLOWED_EVENT_NAMES.include?(event_name)
  end

  def event_is_cacheable?
    # self.class::CACHEABLE_EVENTS is way to access CACHEABLE_EVENTS defined in the class hierarchy of the current object.
    # This ensures that if CACHEABLE_EVENTS is updated elsewhere in it's ancestors, we access the latest value.
    self.class::CACHEABLE_EVENTS.include?(event_name)
  end

  def make_api_call(body)
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{hook.settings['api_key']}"
    }

    Rails.logger.info("OpenAI API request: #{body}")
    response = HTTParty.post(API_URL, headers: headers, body: body)
    Rails.logger.info("OpenAI API response: #{response.body}")

    choices = JSON.parse(response.body)['choices']

    choices.present? ? choices.first['message']['content'] : nil
  end
end
