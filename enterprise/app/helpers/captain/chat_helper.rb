module Captain::ChatHelper
  include Integrations::LlmInstrumentation
  include Captain::ToolExecutionHelper

  def request_chat_completion
    log_chat_completion_request

    chat = build_chat

    add_messages_to_chat(chat)
    with_agent_session do
      response = chat.ask(conversation_messages.last[:content])
      build_response(response)
    end
  rescue StandardError => e
    Rails.logger.error "#{self.class.name} Assistant: #{@assistant.id}, Error in chat completion: #{e}"
    raise e
  end

  private

  def build_chat
    chat = RubyLLM.chat(model: @model)
    chat.with_temperature(@assistant&.config&.[]('temperature').to_f || 1)

    chat = setup_tools(chat)

    system_msg = @messages.find { |m| m[:role] == 'system' || m[:role] == :system }
    chat.with_instructions(system_msg[:content]) if system_msg

    chat
  end

  def setup_tools(chat)
    @tools&.each do |tool|
      chat.with_tool(tool)
    end

    llm_span_name = "llm.captain.#{feature_name}"

    chat.on_new_message do
      start_llm_turn_span(llm_span_name)
    end

    chat.on_end_message do |message|
      end_llm_turn_span(message)
    end
    chat.on_tool_call do |tool_call|
      persist_thinking_message(tool_call)
      start_tool_span(tool_call)
    end

    chat.on_tool_result do |result|
      end_tool_span(result)
    end

    chat
  end

  def add_messages_to_chat(chat)
    conversation_messages[0...-1].each do |msg|
      chat.add_message(role: msg[:role].to_sym, content: msg[:content])
    end
  end

  def instrumentation_params
    {
      span_name: "llm.captain.#{feature_name}",
      account_id: resolved_account_id,
      conversation_id: @conversation_id,
      feature_name: feature_name,
      model: @model,
      messages: @messages,
      temperature: temperature,
      metadata: {
        assistant_id: @assistant&.id
      }
    }
  end

  def chat_parameters
    {
      model: @model,
      messages: @messages,
      tools: @tool_registry&.registered_tools || [],
      response_format: { type: 'json_object' },
      temperature: temperature
    }
  end

  def conversation_messages
    @messages.reject { |m| m[:role] == 'system' || m[:role] == :system }
  end

  def persist_thinking_message(tool_call)
    return unless defined?(@copilot_thread) && @copilot_thread.present?

    tool_name = tool_call.name.to_s

    persist_message(
      {
        'content' => "Using #{tool_name}",
        'function_name' => tool_name
      },
      'assistant_thinking'
    )
  end

  def build_response(response)
    Rails.logger.debug { "#{self.class.name} Assistant: #{@assistant.id}, Received response #{response}" }

    parsed = parse_json_response(response.content)

    persist_message(parsed, 'assistant')
    { 'response' => parsed }
  end

  def parse_json_response(content)
    content = content.gsub('```json', '').gsub('```', '')
    content = content.strip
    JSON.parse(content)
  rescue JSON::ParserError => e
    Rails.logger.error "#{self.class.name} Assistant: #{@assistant.id}, Error parsing JSON response: #{e.message}"
    { 'content' => content }
  end

  def temperature
    @assistant&.config&.[]('temperature').to_f || 1
  end

  def resolved_account_id
    @account&.id || @assistant&.account_id
  end

  # Ensures all LLM calls and tool executions within an agentic loop
  # are grouped under a single trace/session in Langfuse.
  #
  # Without this guard, each recursive call to request_chat_completion
  # (triggered by tool calls) would create a separate trace instead of
  # nesting within the existing session span.
  def with_agent_session(&)
    already_active = @agent_session_active
    return yield if already_active

    @agent_session_active = true
    instrument_agent_session(instrumentation_params, &)
  ensure
    @agent_session_active = false unless already_active
  end

  # Must be implemented by including class to identify the feature for instrumentation.
  # Used for Langfuse tagging and span naming.
  def feature_name
    raise NotImplementedError, "#{self.class.name} must implement #feature_name"
  end

  def log_chat_completion_request
    Rails.logger.info(
      "#{self.class.name} Assistant: #{@assistant.id}, Requesting chat completion
      for messages #{@messages} with #{@tools&.length || 0} tools
      "
    )
  end
end
