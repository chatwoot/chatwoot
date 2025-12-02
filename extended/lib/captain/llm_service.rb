require_relative 'llm/providers/openai_provider'
require_relative 'llm/providers/gemini_provider'

class Captain::LlmService
  def initialize(api_key: nil, provider: nil)
    @provider = determine_provider(provider)
    @api_key = api_key || default_api_key
    @client = create_client
    @logger = Rails.logger
  end

  def call(messages, functions = [], model: default_model, json_mode: true)
    response = @client.chat(
      messages: messages,
      functions: functions,
      model: model,
      json_mode: json_mode
    )
    handle_response(response)
  rescue StandardError => e
    handle_error(e)
  end

  private

  def determine_provider(provider)
    provider || ENV['CAPTAIN_LLM_PROVIDER'] || 'openai'
  end

  def default_api_key
    case @provider
    when 'gemini'
      ENV['GEMINI_API_KEY'] || InstallationConfig.find_by(name: 'CAPTAIN_GEMINI_API_KEY')&.value
    else
      ENV['OPENAI_API_KEY'] || InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
    end
  end

  def default_model
    case @provider
    when 'gemini'
      'gemini-1.5-flash'
    else
      'gpt-4o-mini'
    end
  end

  def create_client
    case @provider
    when 'gemini'
      Captain::Llm::Providers::GeminiProvider.new(api_key: @api_key)
    else
      endpoint = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_ENDPOINT')&.value
      Captain::Llm::Providers::OpenaiProvider.new(api_key: @api_key, endpoint: endpoint)
    end
  end

  def handle_response(response)
    if response['choices'][0]['message']['tool_calls']
      handle_tool_calls(response)
    else
      handle_direct_response(response)
    end
  end

  def handle_tool_calls(response)
    tool_call = response['choices'][0]['message']['tool_calls'][0]
    {
      tool_call: tool_call,
      output: nil,
      stop: false
    }
  end

  def handle_direct_response(response)
    content = response.dig('choices', 0, 'message', 'content').strip
    parsed = JSON.parse(content)

    {
      output: parsed['result'] || parsed['thought_process'],
      stop: parsed['stop'] || false
    }
  rescue JSON::ParserError => e
    handle_error(e, content)
  end

  def handle_error(error, content = nil)
    @logger.error("LLM call failed: #{error.message}")
    @logger.error(error.backtrace.join("\n"))
    @logger.error("Content: #{content}") if content

    { output: 'Error occurred, retrying', stop: false }
  end
end
