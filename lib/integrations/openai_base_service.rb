class Integrations::OpenaiBaseService
  include Integrations::LlmInstrumentation

  # gpt-4o-mini supports 128,000 tokens
  # 1 token is approx 4 characters
  # sticking with 120000 to be safe
  # 120000 * 4 = 480,000 characters (rounding off downwards to 400,000 to be safe)
  TOKEN_LIMIT = 400_000
  GPT_MODEL = Integrations::OpenaiConstants.model.freeze

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

    deserialize_cached_value(Redis::Alfred.get(cache_key))
  end

  def deserialize_cached_value(value)
    return nil if value.blank?

    JSON.parse(value, symbolize_names: true)
  rescue JSON::ParserError
    # If json parse failed, returning the value as is will fail too
    # since we access the keys as symbols down the line
    # So it's best to return nil
    nil
  end

  def save_to_cache(response)
    return nil unless event_is_cacheable?

    # Serialize to JSON
    # This makes parsing easy when response is a hash
    Redis::Alfred.setex(cache_key, response.to_json)
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

  def api_url
    endpoint = Integrations::OpenaiConstants.endpoint.chomp('/')
    "#{endpoint}/v1/chat/completions"
  end

  def make_api_call(body)
    parsed_body = JSON.parse(body)
    instrumentation_params = build_instrumentation_params(parsed_body)

    instrument_llm_call(instrumentation_params) do
      execute_api_request(body, parsed_body['messages'])
    end
  end

  def build_instrumentation_params(parsed_body)
    {
      span_name: "llm.#{event_name}",
      account_id: hook.account_id,
      conversation_id: conversation&.display_id,
      feature_name: event_name,
      model: parsed_body['model'],
      messages: parsed_body['messages'],
      temperature: parsed_body['temperature']
    }
  end

  def execute_api_request(body, messages)
    Rails.logger.info("OpenAI API request: #{body}")
    response = HTTParty.post(api_url, headers: api_headers, body: body)
    Rails.logger.info("OpenAI API response: #{response.body}")

    parse_api_response(response, messages)
  end

  def api_headers
    {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{hook.settings['api_key']}"
    }
  end

  def parse_api_response(response, messages)
    return build_error_response(response, messages) unless response.success?

    parsed_response = JSON.parse(response.body)
    build_success_response(parsed_response, messages)
  end

  def build_error_response(response, messages)
    { error: response.parsed_response, error_code: response.code, request_messages: messages }
  end

  def build_success_response(parsed_response, messages)
    choices = parsed_response['choices']
    usage = parsed_response['usage']
    message_content = choices.present? ? choices.first['message']['content'] : nil

    { message: message_content, usage: usage, request_messages: messages }
  end
end
