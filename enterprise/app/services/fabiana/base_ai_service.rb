class Fabiana::BaseAiService
  class UnsupportedProviderError < StandardError; end
  class MissingApiKeyError < StandardError; end
  class ApiError < StandardError; end

  SUPPORTED_PROVIDERS = %w[openai chatgpt groq].freeze
  
  DEFAULT_MODELS = {
    'openai' => 'gpt-4o-mini',
    'chatgpt' => 'gpt-4',
    'groq' => 'llama3-8b-8192'
  }.freeze

  DEFAULT_ENDPOINTS = {
    'openai' => 'https://api.openai.com/',
    'chatgpt' => 'https://api.openai.com/',
    'groq' => 'https://api.groq.com/openai/'
  }.freeze

  def initialize
    @provider = get_provider
    @client = create_client
    @model = get_model
    setup_provider_specific_config
  rescue StandardError => e
    raise "Failed to initialize Fabiana AI client: #{e.message}"
  end

  def generate_response(messages, functions = [])
    case @provider
    when 'openai', 'chatgpt'
      generate_openai_response(messages, functions)
    when 'groq'
      generate_groq_response(messages, functions)
    else
      raise UnsupportedProviderError, "Provider #{@provider} is not supported"
    end
  rescue StandardError => e
    Rails.logger.error "Fabiana AI Error (#{@provider}): #{e.message}"
    raise ApiError, "Failed to generate response: #{e.message}"
  end

  private

  def get_provider
    provider = InstallationConfig.find_by(name: 'FABIANA_AI_PROVIDER')&.value || 'openai'
    unless SUPPORTED_PROVIDERS.include?(provider)
      raise UnsupportedProviderError, "Unsupported provider: #{provider}"
    end
    provider
  end

  def get_api_key
    key_name = "FABIANA_#{@provider.upcase}_API_KEY"
    api_key = InstallationConfig.find_by(name: key_name)&.value
    raise MissingApiKeyError, "Missing API key for #{@provider}" if api_key.blank?
    api_key
  end

  def get_endpoint
    endpoint_name = "FABIANA_#{@provider.upcase}_ENDPOINT"
    endpoint = InstallationConfig.find_by(name: endpoint_name)&.value
    endpoint.presence || DEFAULT_ENDPOINTS[@provider]
  end

  def get_model
    model_name = "FABIANA_#{@provider.upcase}_MODEL"
    model = InstallationConfig.find_by(name: model_name)&.value
    model.presence || DEFAULT_MODELS[@provider]
  end

  def create_client
    require 'openai' # All providers use OpenAI-compatible API
    
    OpenAI::Client.new(
      access_token: get_api_key,
      uri_base: get_endpoint,
      log_errors: Rails.env.development?
    )
  end

  def setup_provider_specific_config
    case @provider
    when 'groq'
      # Groq specific configurations
      @max_tokens = 8192
      @temperature = 0.7
    when 'chatgpt', 'openai'
      # OpenAI specific configurations
      @max_tokens = 4096
      @temperature = 0.7
    end
  end

  def generate_openai_response(messages, functions = [])
    params = {
      model: @model,
      messages: messages,
      temperature: @temperature,
      max_tokens: @max_tokens
    }
    
    # Add response format for structured output if needed
    params[:response_format] = { type: 'json_object' } if structured_output_needed?(messages)
    params[:tools] = functions if functions.any?

    response = @client.chat(parameters: params)
    handle_openai_response(response)
  end

  def generate_groq_response(messages, functions = [])
    params = {
      model: @model,
      messages: messages,
      temperature: @temperature,
      max_tokens: @max_tokens
    }
    
    # Groq doesn't support all OpenAI features, so we adapt
    params[:tools] = functions if functions.any? && groq_supports_tools?

    response = @client.chat(parameters: params)
    handle_groq_response(response)
  end

  def handle_openai_response(response)
    if response['choices'][0]['message']['tool_calls']
      handle_tool_calls(response)
    else
      handle_direct_response(response)
    end
  end

  def handle_groq_response(response)
    # Groq responses are similar to OpenAI but may have different structure
    content = response.dig('choices', 0, 'message', 'content')
    {
      output: content,
      stop: true,
      provider: @provider,
      model: @model
    }
  end

  def handle_tool_calls(response)
    tool_calls = response['choices'][0]['message']['tool_calls']
    {
      output: nil,
      tool_calls: tool_calls,
      stop: false,
      provider: @provider,
      model: @model
    }
  end

  def handle_direct_response(response)
    content = response.dig('choices', 0, 'message', 'content')
    {
      output: content,
      stop: true,
      provider: @provider,
      model: @model
    }
  end

  def structured_output_needed?(messages)
    # Check if we need structured JSON output based on message content
    messages.any? { |msg| msg[:content]&.include?('JSON') || msg[:content]&.include?('json') }
  end

  def groq_supports_tools?
    # Check if the current Groq model supports function calling
    # This may vary by model
    %w[llama3-70b-8192 mixtral-8x7b-32768].include?(@model)
  end
end
