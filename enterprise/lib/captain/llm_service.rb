require 'openai'

class Captain::LlmService
  include Integrations::LlmInstrumentation

  MODEL = 'gpt-4o'.freeze

  def initialize(config)
    @client = OpenAI::Client.new(
      access_token: config[:api_key],
      log_errors: Rails.env.development?
    )
    @account_id = config[:account_id]
    @feature_name = config[:feature_name] || 'captain_agent'
    @logger = Rails.logger
  end

  def call(messages, functions = [])
    openai_params = build_openai_params(messages, functions)

    response = instrument_llm_call(build_instrumentation_params(messages)) do
      @client.chat(parameters: openai_params)
    end

    handle_response(response)
  rescue StandardError => e
    handle_error(e)
  end

  private

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

  def build_openai_params(messages, functions)
    params = {
      model: MODEL,
      response_format: { type: 'json_object' },
      messages: messages
    }
    params[:tools] = functions if functions.any?
    params
  end

  def build_instrumentation_params(messages)
    {
      span_name: "llm.#{@feature_name}",
      account_id: @account_id,
      feature_name: @feature_name,
      model: MODEL,
      messages: messages
    }
  end
end
