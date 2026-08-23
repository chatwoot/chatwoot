class Captain::Conversation::AnswerOrEscalateService
  # The decision output of the guard. `decision` is one of :answer, :clarify,
  # :retry, or :handoff. `reason_category` is present only for :handoff and is one
  # of the coded categories used to classify why a conversation needed a human.
  Result = Struct.new(:decision, :reason_category, keyword_init: true)

  # The runner signals a generation failure via a sentinel response rather than
  # raising. Any response carrying this sentinel or the error flag has no real
  # content to deliver.
  HANDOFF_SENTINEL = 'conversation_handoff'.freeze

  # Error reasons that indicate a transient infrastructure problem rather than a
  # genuine gap in knowledge or capability. These must not trigger a human
  # handoff; the pipeline retries or asks a graceful follow-up instead.
  TRANSIENT_FAILURE_MARKERS = [
    /timeout/i,
    /faraday/i,
    /openai/i,
    /net::readtimeout/i,
    /internal_timeout/i,
    /agent_internal_content_leaked/i,
    /rate.?limit/i,
    /bad request/i
  ].freeze

  def initialize(conversation:, assistant:, response: {})
    @conversation = conversation
    @assistant = assistant
    @response = response || {}
  end

  # Applies the "answer by default, hand off only as an absolute last resort"
  # policy to a single agent run result. Returns a Result describing what the
  # pipeline should do next. Note: explicit customer-requested transfers are not
  # decided here — the HandoffTool enforces that consent gate inside the agent
  # loop, so the guard only has to classify unanswered/errored runs.
  def decide
    return Result.new(decision: :retry) if transient_failure?
    return Result.new(decision: :clarify) if clarification_requested?
    return Result.new(decision: :answer) if deliverable_response?

    Result.new(decision: :handoff, reason_category: 'missing_knowledge')
  end

  private

  def transient_failure?
    return false unless @response['error'] || error_reason_present?

    TRANSIENT_FAILURE_MARKERS.any? { |marker| error_reason.match?(marker) }
  end

  # A clarifiable outcome is a follow-up question the agent posed because its
  # knowledge was partial or the request was ambiguous. It is still delivered to
  # the customer, but recorded distinctly so the decision trace shows the agent
  # chose to ask rather than answer.
  def clarification_requested?
    deliverable_response? && response_text.strip.end_with?('?')
  end

  def deliverable_response?
    !@response['error'] && response_text.present? && response_text != HANDOFF_SENTINEL
  end

  def response_text
    @response['response'].to_s
  end

  def error_reason
    @response['error_reason'].to_s
  end

  def error_reason_present?
    error_reason.present?
  end
end
