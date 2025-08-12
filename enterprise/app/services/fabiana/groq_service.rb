require 'openai'

class Fabiana::GroqService < Fabiana::BaseAiService
  # Groq supported models
  GROQ_MODELS = {
    'llama3-8b-8192' => { max_tokens: 8192, supports_tools: false },
    'llama3-70b-8192' => { max_tokens: 8192, supports_tools: true },
    'mixtral-8x7b-32768' => { max_tokens: 32768, supports_tools: true },
    'gemma-7b-it' => { max_tokens: 8192, supports_tools: false }
  }.freeze

  def initialize
    @provider = 'groq'
    @client = create_groq_client
    @model = get_model
    @model_config = GROQ_MODELS[@model] || GROQ_MODELS['llama3-8b-8192']
  end

  def generate_response(messages, functions = [])
    params = build_groq_params(messages, functions)
    response = @client.chat(parameters: params)
    handle_groq_response(response)
  rescue StandardError => e
    Rails.logger.error "Fabiana Groq Error: #{e.message}"
    raise ApiError, "Groq API failed: #{e.message}"
  end

  private

  def create_groq_client
    OpenAI::Client.new(
      access_token: get_groq_api_key,
      uri_base: get_groq_endpoint,
      log_errors: Rails.env.development?
    )
  end

  def get_groq_api_key
    api_key = InstallationConfig.find_by(name: 'FABIANA_GROQ_API_KEY')&.value
    raise MissingApiKeyError, "Missing Groq API key" if api_key.blank?
    api_key
  end

  def get_groq_endpoint
    endpoint = InstallationConfig.find_by(name: 'FABIANA_GROQ_ENDPOINT')&.value
    endpoint.presence || 'https://api.groq.com/openai/'
  end

  def get_model
    model = InstallationConfig.find_by(name: 'FABIANA_GROQ_MODEL')&.value
    model.presence || 'llama3-8b-8192'
  end

  def build_groq_params(messages, functions)
    params = {
      model: @model,
      messages: optimize_messages_for_groq(messages),
      temperature: 0.7,
      max_tokens: [@model_config[:max_tokens], 4096].min, # Limit for safety
      top_p: 0.9,
      stream: false
    }

    # Only add tools if the model supports them
    if functions.any? && @model_config[:supports_tools]
      params[:tools] = functions
    elsif functions.any?
      Rails.logger.warn "Groq model #{@model} doesn't support function calling. Functions ignored."
    end

    params
  end

  def optimize_messages_for_groq(messages)
    # Groq works better with optimized prompts
    enhanced = messages.dup
    
    # Add Groq-optimized system message if not present
    unless has_system_message?(enhanced)
      enhanced.unshift({
        role: 'system',
        content: build_groq_system_message
      })
    end

    # Ensure messages are properly formatted for Groq
    enhanced.map do |msg|
      {
        role: msg[:role] || msg['role'],
        content: optimize_content_for_groq(msg[:content] || msg['content'])
      }
    end
  end

  def build_groq_system_message
    <<~SYSTEM
      You are Fabiana, an intelligent AI assistant specialized in customer support.
      
      Guidelines:
      - Provide clear, concise, and helpful responses
      - Be professional yet friendly
      - Focus on solving customer problems efficiently
      - If you need to escalate to a human agent, clearly indicate this
      - Always maintain a positive and supportive tone
    SYSTEM
  end

  def optimize_content_for_groq(content)
    return content if content.blank?
    
    # Groq performs better with well-structured content
    content.strip
  end

  def has_system_message?(messages)
    messages.any? { |msg| (msg[:role] || msg['role']) == 'system' }
  end

  def handle_groq_response(response)
    choice = response['choices'][0]
    message = choice['message']

    # Groq response structure
    if message['tool_calls'] && @model_config[:supports_tools]
      {
        output: nil,
        tool_calls: message['tool_calls'],
        stop: false,
        provider: 'groq',
        model: @model,
        usage: response['usage'],
        finish_reason: choice['finish_reason']
      }
    else
      {
        output: message['content'],
        stop: true,
        provider: 'groq',
        model: @model,
        usage: response['usage'],
        finish_reason: choice['finish_reason']
      }
    end
  end

  def self.available_models
    GROQ_MODELS.keys
  end

  def self.model_supports_tools?(model)
    GROQ_MODELS.dig(model, :supports_tools) || false
  end
end
