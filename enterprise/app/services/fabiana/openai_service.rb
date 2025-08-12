require 'openai'

class Fabiana::OpenaiService < Fabiana::BaseAiService
  def initialize
    @provider = 'openai'
    @client = create_openai_client
    @model = get_model
  end

  def generate_response(messages, functions = [])
    params = build_openai_params(messages, functions)
    response = @client.chat(parameters: params)
    handle_openai_response(response)
  rescue StandardError => e
    Rails.logger.error "Fabiana OpenAI Error: #{e.message}"
    raise ApiError, "OpenAI API failed: #{e.message}"
  end

  private

  def create_openai_client
    OpenAI::Client.new(
      access_token: get_openai_api_key,
      uri_base: get_openai_endpoint,
      log_errors: Rails.env.development?
    )
  end

  def get_openai_api_key
    api_key = InstallationConfig.find_by(name: 'FABIANA_OPEN_AI_API_KEY')&.value
    raise MissingApiKeyError, "Missing OpenAI API key" if api_key.blank?
    api_key
  end

  def get_openai_endpoint
    endpoint = InstallationConfig.find_by(name: 'FABIANA_OPEN_AI_ENDPOINT')&.value
    endpoint.presence || 'https://api.openai.com/'
  end

  def get_model
    model = InstallationConfig.find_by(name: 'FABIANA_OPEN_AI_MODEL')&.value
    model.presence || 'gpt-4o-mini'
  end

  def build_openai_params(messages, functions)
    params = {
      model: @model,
      messages: messages,
      temperature: 0.7,
      max_tokens: 4096
    }

    # Add structured output for JSON responses
    if needs_json_response?(messages)
      params[:response_format] = { type: 'json_object' }
    end

    # Add function calling if provided
    params[:tools] = functions if functions.any?

    params
  end

  def needs_json_response?(messages)
    messages.any? do |msg|
      content = msg[:content] || msg['content']
      content&.downcase&.include?('json') || content&.include?('JSON')
    end
  end

  def handle_openai_response(response)
    choice = response['choices'][0]
    message = choice['message']

    if message['tool_calls']
      {
        output: nil,
        tool_calls: message['tool_calls'],
        stop: false,
        provider: 'openai',
        model: @model,
        usage: response['usage']
      }
    else
      {
        output: message['content'],
        stop: true,
        provider: 'openai',
        model: @model,
        usage: response['usage']
      }
    end
  end
end
