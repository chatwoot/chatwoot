require 'openai'

class Fabiana::ChatgptService < Fabiana::BaseAiService
  def initialize
    @provider = 'chatgpt'
    @client = create_chatgpt_client
    @model = get_model
  end

  def generate_response(messages, functions = [])
    params = build_chatgpt_params(messages, functions)
    response = @client.chat(parameters: params)
    handle_chatgpt_response(response)
  rescue StandardError => e
    Rails.logger.error "Fabiana ChatGPT Error: #{e.message}"
    raise ApiError, "ChatGPT API failed: #{e.message}"
  end

  private

  def create_chatgpt_client
    OpenAI::Client.new(
      access_token: get_chatgpt_api_key,
      uri_base: get_chatgpt_endpoint,
      log_errors: Rails.env.development?
    )
  end

  def get_chatgpt_api_key
    api_key = InstallationConfig.find_by(name: 'FABIANA_CHATGPT_API_KEY')&.value
    raise MissingApiKeyError, "Missing ChatGPT API key" if api_key.blank?
    api_key
  end

  def get_chatgpt_endpoint
    endpoint = InstallationConfig.find_by(name: 'FABIANA_CHATGPT_ENDPOINT')&.value
    endpoint.presence || 'https://api.openai.com/'
  end

  def get_model
    model = InstallationConfig.find_by(name: 'FABIANA_CHATGPT_MODEL')&.value
    model.presence || 'gpt-4'
  end

  def build_chatgpt_params(messages, functions)
    params = {
      model: @model,
      messages: enhance_messages_for_chatgpt(messages),
      temperature: 0.8, # Slightly higher for more creative responses
      max_tokens: 4096,
      presence_penalty: 0.1,
      frequency_penalty: 0.1
    }

    # ChatGPT specific optimizations
    if needs_json_response?(messages)
      params[:response_format] = { type: 'json_object' }
    end

    # Add function calling if provided
    params[:tools] = functions if functions.any?

    params
  end

  def enhance_messages_for_chatgpt(messages)
    # Add ChatGPT-specific system message if not present
    enhanced = messages.dup
    
    unless has_system_message?(enhanced)
      enhanced.unshift({
        role: 'system',
        content: 'You are Fabiana, a helpful AI assistant for customer support. Provide clear, friendly, and professional responses.'
      })
    end

    enhanced
  end

  def has_system_message?(messages)
    messages.any? { |msg| (msg[:role] || msg['role']) == 'system' }
  end

  def needs_json_response?(messages)
    messages.any? do |msg|
      content = msg[:content] || msg['content']
      content&.downcase&.include?('json') || content&.include?('JSON')
    end
  end

  def handle_chatgpt_response(response)
    choice = response['choices'][0]
    message = choice['message']

    if message['tool_calls']
      {
        output: nil,
        tool_calls: message['tool_calls'],
        stop: false,
        provider: 'chatgpt',
        model: @model,
        usage: response['usage'],
        finish_reason: choice['finish_reason']
      }
    else
      {
        output: message['content'],
        stop: true,
        provider: 'chatgpt',
        model: @model,
        usage: response['usage'],
        finish_reason: choice['finish_reason']
      }
    end
  end
end
