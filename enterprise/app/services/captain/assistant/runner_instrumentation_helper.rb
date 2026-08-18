module Captain::Assistant::RunnerInstrumentationHelper
  include Integrations::LlmInstrumentationConstants

  TRACE_CONFIG = {
    assistant: {
      name: 'llm.captain_v2',
      tags: ['captain_v2']
    },
    reply_suggestion: {
      name: 'llm.captain.copilot.agent',
      tags: ['copilot']
    }
  }.freeze

  private

  def install_instrumentation(runner)
    return unless ChatwootApp.otel_enabled?

    config = trace_config
    Agents::Instrumentation.install(
      runner,
      tracer: OpentelemetryConfig.tracer,
      trace_name: config[:name],
      span_attributes: {
        ATTR_LANGFUSE_TAGS => config[:tags].to_json
      },
      attribute_provider: Captain::Assistant::InstrumentationAttributeProvider.new(self)
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
      format(ATTR_LANGFUSE_METADATA, 'conversation_display_id') => conversation[:display_id],
      format(ATTR_LANGFUSE_METADATA, 'channel_type') => state[:channel_type],
      format(ATTR_LANGFUSE_METADATA, 'source') => state[:source],
      ATTR_LANGFUSE_TRACE_INPUT => trace_input,
      ATTR_LANGFUSE_OBSERVATION_INPUT => trace_input
    }.compact.transform_values(&:to_s)
  end

  def add_usage_metadata_callback(runner)
    handoff_tool_name = Captain::Tools::HandoffTool.new(@assistant).name

    # Tool tracking always runs — process_response in the job consumes the resulting
    # handoff_tool_called flag regardless of whether OTEL is enabled.
    runner.on_tool_complete do |tool_name, _tool_result, context_wrapper|
      track_handoff_usage(tool_name, handoff_tool_name, context_wrapper)
    end

    return runner if reply_suggestion?

    if message_burst_protection_active?
      runner.on_run_complete do |_agent_name, _result, context_wrapper|
        @response_discarded = newer_customer_message_arrived?
        write_run_metadata(context_wrapper) if ChatwootApp.otel_enabled?
      end
    elsif ChatwootApp.otel_enabled?
      runner.on_run_complete do |_agent_name, _result, context_wrapper|
        write_credits_used_metadata(context_wrapper)
      end
    end
    runner
  end

  def track_handoff_usage(tool_name, handoff_tool_name, context_wrapper)
    return unless context_wrapper&.context
    return unless tool_name.to_s == handoff_tool_name

    # Mirror the flag onto the instance so error_response can surface it even when
    # the runner raises before returning a result (the context is unreachable then).
    context_wrapper.context[:captain_v2_handoff_tool_called] = true
    @handoff_tool_called = true

    return unless context_wrapper.context.dig(:state, :captain_v2_handoff_tool_completed)

    @handoff_tool_completed = true
  end

  def write_run_metadata(context_wrapper)
    root_span = context_wrapper&.context&.dig(:__otel_tracing, :root_span)
    return unless root_span

    root_span.set_attribute(format(ATTR_LANGFUSE_METADATA, 'discarded'), response_discarded?.to_s)
    root_span.set_attribute(format(ATTR_LANGFUSE_METADATA, 'credit_used'), (!@handoff_tool_called && !response_discarded?).to_s)
  end

  def write_credits_used_metadata(context_wrapper)
    root_span = context_wrapper&.context&.dig(:__otel_tracing, :root_span)
    return unless root_span

    root_span.set_attribute(format(ATTR_LANGFUSE_METADATA, 'credit_used'), @handoff_tool_called ? 'false' : 'true')
  end

  def message_burst_protection_active? = @responding_to_message_id.present?

  def newer_customer_message_arrived?
    return false if @responding_to_message_id.blank? || @conversation.blank?

    Conversation.uncached do
      @conversation.messages
                   .captain_response_triggering
                   .exists?(['messages.id > ?', @responding_to_message_id])
    end
  end

  def trace_config
    TRACE_CONFIG.fetch(reply_suggestion? ? :reply_suggestion : :assistant)
  end
end
