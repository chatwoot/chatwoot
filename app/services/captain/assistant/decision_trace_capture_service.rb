# Persists an observable decision trace for a real conversation run so agents can
# inspect exactly how Captain reasoned (nodes activated, tool calls, handoffs) in
# the Debug tab. Never raises: a trace-logging bug must not roll back the customer
# reply that triggered it.
class Captain::Assistant::DecisionTraceCaptureService
  def initialize(assistant:, conversation:, response:, decision_trace:, source: 'conversation')
    @assistant = assistant
    @conversation = conversation
    @response = response
    @decision_trace = decision_trace
    @source = source
  end

  def capture
    return if @decision_trace.blank? && @response.to_h['simple_reply'].blank?

    Captain::AgentTrace.create!(
      account: @assistant.account,
      assistant: @assistant,
      conversation: @conversation,
      source: @source,
      input_message: input_message,
      trace: @decision_trace,
      response: sanitized_response,
      outcome: outcome,
      error_reason: @response['error_reason']
    )
  rescue StandardError => e
    ChatwootExceptionTracker.new(e, account: @assistant.account).capture_exception
    Rails.logger.error("[CAPTAIN][DecisionTraceCaptureService] Capture failed for conversation=#{@conversation&.display_id}: #{e.message}")
  end

  private

  def input_message
    last_user_node = @decision_trace.reverse.find { |node| node['type'] == 'agent_activated' }
    return nil if last_user_node.blank?

    last_user_node['input'].to_s.first(500)
  end

  def sanitized_response
    {
      'response' => @response['response'],
      'reasoning' => @response['reasoning'],
      'handoff_tool_called' => @response['handoff_tool_called'],
      'handoff_offer_pending' => @response['handoff_offer_pending'],
      'simple_reply' => @response['simple_reply']
    }.compact
  end

  def outcome
    return 'error' if @response['error']
    return 'simple_reply' if @response['simple_reply']
    return 'offer' if @response['handoff_offer_pending']
    return 'handoff' if @response['handoff_tool_called']

    'answered'
  end
end
