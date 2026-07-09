class Captain::Assistant::SessionCaptureService
  SCENARIO_AGENT_REGEX = /\A#{Captain::Scenario::HANDOFF_KEY_PREFIX}_(\d+)_/

  def initialize(assistant:, conversation:, run_result:, result_message:, credits_consumed:)
    @assistant = assistant
    @conversation = conversation
    @run_result = run_result
    @result_message = result_message
    @credits_consumed = credits_consumed
  end

  # Capture must never break response delivery: swallow and report failures.
  def capture
    return if @run_result.blank?

    capture!
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @assistant.account).capture_exception
    Rails.logger.error("[CAPTAIN][SessionCaptureService] Capture failed for conversation=#{@conversation.display_id}: #{e.message}")
  end

  def capture!
    Captain::Session.create!(
      account_id: @assistant.account_id,
      assistant: @assistant,
      session_type: :assistant,
      subject_id: @conversation.id,
      result_id: @result_message&.id,
      scenario_id: scenario_id,
      llm_model: @assistant.agent_model,
      credits_consumed: @credits_consumed,
      faq_ids: state[:faq_ids] || [],
      document_ids: state[:document_ids] || [],
      run_context: run_context_payload
    )
  end

  private

  def context
    @run_result.context || {}
  end

  def state
    context[:state] || {}
  end

  def scenario_id
    match = context[:current_agent].to_s.match(SCENARIO_AGENT_REGEX)
    return if match.blank?

    @assistant.scenarios.find_by(id: match[1])&.id
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
