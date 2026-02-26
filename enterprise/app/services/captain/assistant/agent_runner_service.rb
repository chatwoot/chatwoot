require 'agents'
require 'agents/instrumentation'

class Captain::Assistant::AgentRunnerService
  include Integrations::LlmInstrumentationConstants
  include Captain::Assistant::RunnerCallbacksHelper
  include Captain::Assistant::TracePayloadHelper

  CONVERSATION_STATE_ATTRIBUTES = %i[
    id display_id inbox_id contact_id status priority
    label_list custom_attributes additional_attributes
  ].freeze

  CONTACT_STATE_ATTRIBUTES = %i[
    id name email phone_number identifier contact_type
    custom_attributes additional_attributes
  ].freeze

  CONTACT_INBOX_STATE_ATTRIBUTES = %i[id hmac_verified].freeze

  CAMPAIGN_STATE_ATTRIBUTES = %i[id title message campaign_type description].freeze

  def initialize(assistant:, conversation: nil, callbacks: {})
    @assistant = assistant
    @conversation = conversation
    @callbacks = callbacks
  end

  def generate_response(message_history: [])
    message_to_process, context = run_payload(message_history)
    result = runner.run(message_to_process, context: context, max_turns: 100)

    process_agent_result(result)
  rescue StandardError => e
    # when running the agent runner service in a rake task, the conversation might not have an account associated
    # for regular production usage, it will run just fine
    ChatwootExceptionTracker.new(e, account: @conversation&.account).capture_exception
    Rails.logger.error "[Captain V2] AgentRunnerService error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    error_response(e.message)
  end

  private

  def build_context(message_history)
    conversation_history = message_history.map do |msg|
      content = msg[:content]
      # Preserve multimodal arrays (with image_url entries) as-is for the runner to restore with attachments.
      # Only extract text from non-array formats (hashes from agent structured output, plain strings).
      content = extract_text_from_content(content) unless content.is_a?(Array)

      {
        role: msg[:role].to_sym,
        content: content,
        agent_name: msg[:agent_name]
      }
    end

    {
      session_id: "#{@assistant.account_id}_#{@conversation&.display_id}",
      conversation_history: conversation_history,
      state: build_state
    }
  end

  def extract_last_user_message(message_history)
    last_user_msg = message_history.reverse.find { |msg| msg[:role] == 'user' }
    return '' if last_user_msg.blank?

    content = last_user_msg[:content]
    return extract_text_from_content(content) unless content.is_a?(Array)

    text, attachments = Captain::OpenAiMessageBuilderService.extract_text_and_attachments(content)
    return text if attachments.blank?

    RubyLLM::Content.new(text, attachments)
  end

  def message_history_without_last_user_message(message_history)
    last_user_index = message_history.rindex { |msg| msg[:role] == 'user' }
    return message_history if last_user_index.nil?

    message_history.reject.with_index { |_msg, index| index == last_user_index }
  end

  def extract_text_from_content(content)
    # Handle structured output from agents
    return content[:response] || content['response'] || content.to_s if content.is_a?(Hash)

    return content unless content.is_a?(Array)

    text_parts = content.select { |part| part[:type] == 'text' }.pluck(:text)
    text_parts.join(' ')
  end

  # Response formatting methods
  def process_agent_result(result)
    Rails.logger.info "[Captain V2] Agent result: #{result.inspect}"
    response = format_response(result.output)

    # Extract agent name from context
    response['agent_name'] = result.context&.dig(:current_agent)

    response
  end

  def format_response(output)
    return output.with_indifferent_access if output.is_a?(Hash)

    # Fallback for backwards compatibility
    {
      'response' => output.to_s,
      'reasoning' => 'Processed by agent'
    }
  end

  def error_response(error_message)
    {
      'response' => 'conversation_handoff',
      'reasoning' => "Error occurred: #{error_message}"
    }
  end

  def build_state
    state = {
      account_id: @assistant.account_id,
      assistant_id: @assistant.id,
      assistant_config: @assistant.config
    }

    if @conversation
      state[:conversation] = @conversation.attributes.symbolize_keys.slice(*CONVERSATION_STATE_ATTRIBUTES)
      state[:channel_type] = @conversation.inbox&.channel_type
      if @conversation.contact_inbox
        state[:contact_inbox] =
          @conversation.contact_inbox.attributes.symbolize_keys.slice(*CONTACT_INBOX_STATE_ATTRIBUTES)
      end
      state[:contact] = @conversation.contact.attributes.symbolize_keys.slice(*CONTACT_STATE_ATTRIBUTES) if @conversation.contact
      state[:campaign] = @conversation.campaign.attributes.symbolize_keys.slice(*CAMPAIGN_STATE_ATTRIBUTES) if @conversation.campaign
    end

    state
  end

  def build_and_wire_agents
    assistant_agent = @assistant.agent
    scenario_agents = @assistant.scenarios.enabled.map(&:agent)

    assistant_agent.register_handoffs(*scenario_agents) if scenario_agents.any?
    scenario_agents.each { |scenario_agent| scenario_agent.register_handoffs(assistant_agent) }

    [assistant_agent] + scenario_agents
  end

  def install_instrumentation(runner)
    return unless ChatwootApp.otel_enabled?

    Agents::Instrumentation.install(
      runner,
      tracer: OpentelemetryConfig.tracer,
      trace_name: 'llm.captain_v2',
      span_attributes: {
        ATTR_LANGFUSE_TAGS => ['captain_v2'].to_json
      },
      attribute_provider: ->(context_wrapper) { dynamic_trace_attributes(context_wrapper) }
    )
    register_trace_input_callback(runner)
  end

  def dynamic_trace_attributes(context_wrapper)
    state = context_wrapper&.context&.dig(:state) || {}
    conversation = state[:conversation] || {}
    trace_input = context_wrapper&.context&.dig(:captain_v2_trace_input)

    {
      ATTR_LANGFUSE_USER_ID => state[:account_id],
      format(ATTR_LANGFUSE_METADATA, 'assistant_id') => state[:assistant_id],
      format(ATTR_LANGFUSE_METADATA, 'conversation_id') => conversation[:id],
      format(ATTR_LANGFUSE_METADATA, 'conversation_display_id') => conversation[:display_id],
      format(ATTR_LANGFUSE_METADATA, 'channel_type') => state[:channel_type],
      ATTR_LANGFUSE_TRACE_INPUT => trace_input,
      ATTR_LANGFUSE_OBSERVATION_INPUT => trace_input
    }.compact.transform_values(&:to_s)
  end

  def add_usage_metadata_callback(runner)
    return runner unless ChatwootApp.otel_enabled?

    handoff_tool_name = Captain::Tools::HandoffTool.new(@assistant).name

    runner.on_tool_complete do |tool_name, _tool_result, context_wrapper|
      track_handoff_usage(tool_name, handoff_tool_name, context_wrapper)
    end

    runner.on_run_complete do |_agent_name, _result, context_wrapper|
      write_credits_used_metadata(context_wrapper)
    end
    runner
  end

  def track_handoff_usage(tool_name, handoff_tool_name, context_wrapper)
    return unless context_wrapper&.context
    return unless tool_name.to_s == handoff_tool_name

    context_wrapper.context[:captain_v2_handoff_tool_called] = true
  end

  def write_credits_used_metadata(context_wrapper)
    root_span = context_wrapper&.context&.dig(:__otel_tracing, :root_span)
    return unless root_span

    credit_used = !context_wrapper.context[:captain_v2_handoff_tool_called]
    root_span.set_attribute(format(ATTR_LANGFUSE_METADATA, 'credit_used'), credit_used.to_s)
  end

  def runner
    @runner ||= begin
      configured_runner = Agents::Runner.with_agents(*build_and_wire_agents)
      configured_runner = add_usage_metadata_callback(configured_runner)
      configured_runner = add_callbacks_to_runner(configured_runner) if @callbacks.any?
      install_instrumentation(configured_runner)
      configured_runner
    end
  end

  def run_payload(message_history)
    message_to_process = extract_last_user_message(message_history)
    context = build_context(message_history_without_last_user_message(message_history))
    enrich_context_with_trace_payload!(context, message_history, message_to_process)
    [message_to_process, context]
  end
end
