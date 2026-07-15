class Captain::Assistant::SessionCaptureService
  SCENARIO_AGENT_REGEX = /\A#{Captain::Scenario::HANDOFF_KEY_PREFIX}_(\d+)_/

  def initialize(assistant:, conversation:, run_result:, result_message:, credits_consumed:)
    @assistant = assistant
    @conversation = conversation
    @run_result = run_result
    @result_message = result_message
    @credits_consumed = credits_consumed
  end

  def capture
    # TODO: Capture failed runs once error-session semantics are defined. For now,
    # only successful runs that produce a customer-facing reply or handoff are recorded.
    return unless @run_result&.success?

    capture!
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @assistant.account).capture_exception
    Rails.logger.error("[CAPTAIN][SessionCaptureService] Capture failed for conversation=#{@conversation.display_id}: #{e.message}")
  end

  def capture!
    model = @assistant.agent_model
    metadata = context.dig(:state, :cw_metadata) || {}

    Captain::AgentSession.create!(
      assistant: @assistant,
      session_type: :assistant,
      subject: @conversation,
      result: @result_message,
      llm_model: "#{Llm::Models.provider_for(model)}-#{model}",
      credits_consumed: @credits_consumed,
      faq_ids: metadata[:faq_ids] || [],
      document_ids: metadata[:document_ids] || [],
      scenario_ids: scenario_ids,
      run_context: run_context_payload
    )
  end

  private

  def context
    @run_result.context || {}
  end

  def scenario_ids
    ids = current_turn_history.filter_map do |message|
      next unless message[:role].to_s == 'assistant'

      message[:agent_name].to_s.match(SCENARIO_AGENT_REGEX)&.[](1)&.to_i
    end.uniq

    ids & @assistant.scenarios.where(id: ids).pluck(:id)
  end

  def run_context_payload
    {
      session_id: context[:session_id],
      current_agent: context[:current_agent],
      turn_count: context[:turn_count],
      conversation_history: current_turn_history,
      usage: usage_payload
    }
  end

  # Trim to the current turn: the last user message and everything after it
  # (assistant replies, tool calls/results, handoff hops).
  def current_turn_history
    history = Array(context[:conversation_history])
    last_user_index = history.rindex { |message| message[:role].to_s == 'user' }
    last_user_index ? history[last_user_index..] : history
  end

  def usage_payload
    usage = @run_result.usage
    return {} if usage.blank?

    { input_tokens: usage.input_tokens, output_tokens: usage.output_tokens, total_tokens: usage.total_tokens }
  end
end
