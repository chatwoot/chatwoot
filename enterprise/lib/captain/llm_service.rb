require 'openai'

class Captain::LlmService
  def initialize(config)
    @client = OpenAI::Client.new(
      access_token: config[:api_key],
      log_errors: Rails.env.development?
    )
    @logger = Rails.logger
  end

  def call(messages, functions = [])
    openai_params = {
      model: 'gpt-4o',
      response_format: { type: 'json_object' },
      messages: messages
    }
    openai_params[:tools] = functions if functions.any?

    response = @client.chat(parameters: openai_params)
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
end
