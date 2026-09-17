# frozen_string_literal: true

module Captain::Apropos::Instrumentation::RuntimeMethods
  def execute(source)
    instrument('llm.apropos.scheme', { 'scheme.source' => source, 'scheme.source_bytes' => source.to_s.bytesize }) do |span|
      @execution_failure = nil
      record('program', { 'source' => source })
      value = scheme.execute(source)
      state # Check that new bindings can be persisted before reporting success.
      output = model_value(present(value))
      record('result', { 'value' => output })
      Captain::Apropos::Instrumentation.set_attributes(span, 'scheme.result' => Captain::Apropos::Instrumentation.summary(output))
      output
    rescue StandardError => e
      @execution_failure = scheme.feedback.render(e, self)
      record('error', @execution_failure.except(:error).merge(message: @execution_failure[:error]).deep_stringify_keys)
      raise
    end
  end

  def langfuse_attributes(role: nil)
    metadata = {
      'account_id' => account.id,
      'user_id' => user.id,
      'session_id' => @trace_context[:session_id],
      'turn_id' => @trace_context[:turn_id],
      'depth' => @depth,
      'role' => role
    }.compact
    {
      'langfuse.user.id' => account.id.to_s,
      'langfuse.session.id' => @trace_context[:session_id]&.to_s,
      'langfuse.trace.tags' => ['apropos'].to_json
    }.compact.merge(metadata.to_h { |key, value| ["langfuse.trace.metadata.#{key}", value.to_s] })
  end

  def run_summary
    usage = events.select { |event| event['kind'] == 'usage' }.pluck('data')
    {
      'langfuse.trace.metadata.agent_calls' => @budget[:calls],
      'langfuse.trace.metadata.query_calls' => @budget[:queries],
      'langfuse.trace.metadata.receipt_count' => receipts.size,
      'gen_ai.usage.input_tokens' => usage.sum { |event| (event[:input_tokens] || event['input_tokens']).to_i },
      'gen_ai.usage.output_tokens' => usage.sum { |event| (event[:output_tokens] || event['output_tokens']).to_i }
    }
  end

  def trace_input(instruction:, input:, role:)
    {
      role: role,
      task: instruction,
      input: Captain::Apropos::Instrumentation.summary(input),
      run_context: run_context
    }
  end

  def agent_role(tools:)
    return 'reason' unless tools

    @depth.zero? ? 'coordinator' : 'worker'
  end

  def instrument(name, attributes = {}, observation_type: nil, &)
    Captain::Apropos::Instrumentation.with_span(name, runtime: self, attributes: attributes, observation_type: observation_type, &)
  end

  def with_agent_tool_context(context_wrapper, &)
    Captain::Apropos::Instrumentation.with_agent_tool_context(context_wrapper, &)
  end

  private

  def setup_execution(execution)
    @budget = execution.fetch(:budget)
    @depth = execution.fetch(:depth)
    @trace_context = execution[:trace_context] || {}
  end

  def instrument_action(name, reference, arguments)
    attributes = {
      'action.name' => name,
      'action.target_type' => reference['type'],
      'action.target_id' => reference['id'],
      'action.argument_names' => arguments.keys.map(&:to_s).sort
    }
    instrument("llm.apropos.action.#{name}", attributes, observation_type: 'tool') do |span|
      receipt = @actions.call(name, reference, arguments)
      Captain::Apropos::Instrumentation.set_attributes(span, {
                                                         'action.status' => receipt['status'],
                                                         'action.effect' => receipt['effect'],
                                                         'action.receipt' => Captain::Apropos::Instrumentation.summary(receipt)
                                                       })
      receipt
    rescue StandardError => e
      Captain::Apropos::Instrumentation.set_attributes(span, 'action.status' => 'failed', 'action.error_class' => e.class.name)
      raise
    end
  end

  def instrument_query_stage(stage, attributes, &)
    instrument("llm.apropos.wootql.#{stage}", attributes, &)
  end
end
