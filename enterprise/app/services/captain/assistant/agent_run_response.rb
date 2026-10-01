module Captain::Assistant::AgentRunResponse
  HANDOFF_SIGNAL = 'conversation_handoff'.freeze

  private

  # A run guard ended the LLM loop, so the halt content is an internal notice and
  # never an answer for the customer. The job routes these through its handoff or
  # discard paths using the flags below.
  def run_halted? = halt_reason.present?

  def halt_reason
    Captain::Tools::RunGuard.halt_reason(@last_run_result&.context&.dig(:state))
  end

  def channel_ready_response
    record_turn_start(@last_run_result)
    @last_run_result = rewrite_oversized_response(@last_run_result) if response_too_long?(@last_run_result)

    raise "Captain response exceeds the channel limit of #{message_length_limit} characters" if response_too_long?(@last_run_result)

    process_agent_result(@last_run_result)
  end

  def halted_run_response
    reason = halt_reason
    Rails.logger.info "[Captain V2] Run halted without a final response: reason=#{reason}"
    # A halted handoff still captures an assistant session, so keep the turn boundary.
    record_turn_start(@last_run_result)
    return handoff_signal_response(reasoning: "Run halted: #{reason}") unless reason == Captain::Tools::RunGuard::TOOL_CALL_BUDGET_EXCEEDED

    handoff_signal_response(reasoning: Captain::Tools::RunGuard::BUDGET_EXCEEDED_MESSAGE, error_reason: reason)
  end

  def process_agent_result(run_result)
    Rails.logger.info "[Captain V2] Agent result: #{run_result.inspect}"
    model_output = run_result.output
    structured_response = if model_output.is_a?(Hash)
                            model_output.with_indifferent_access
                          else
                            { 'response' => model_output.to_s, 'reasoning' => 'Processed by agent' }
                          end
    response_parts = Captain::Assistant::ResponseParts.from_response(structured_response)
    response_parts = response_parts.without_citations unless @assistant.citations_enabled?
    structured_response['response_parts'] = response_parts.to_a
    structured_response['response'] = response_parts.plain_text
    structured_response['agent_name'] = run_result.context&.dig(:current_agent)
    structured_response['handoff_tool_called'] = run_result.context&.dig(:captain_v2_handoff_tool_called) || false
    structured_response
  end

  def rewrite_oversized_response(run_result)
    response_parts = Captain::Assistant::ResponseParts.from_response(run_result.output)
    rendered_customer_message = customer_message_content(run_result)
    citation_markup_length = rendered_customer_message.length - response_parts.plain_text.length
    response_text_limit = message_length_limit - citation_markup_length
    raise 'Captain citation links exceed the channel limit' unless response_text_limit.positive?

    response_rewriter.rewrite(run_result, response_parts: response_parts, response_text_limit: response_text_limit)
  end

  def response_rewriter
    @response_rewriter ||= Captain::Assistant::ResponseRewriter.new(
      assistant: @assistant,
      attribute_provider: Captain::Assistant::InstrumentationAttributeProvider.new(self)
    )
  end

  def record_turn_start(run_result)
    history = Array(run_result.context&.dig(:conversation_history))
    turn_start_index = history.rindex { |message| message[:role].to_s == 'user' }
    run_result.context[:captain_v2_turn_start_index] = turn_start_index if turn_start_index
  end

  def response_too_long?(run_result)
    message_length_limit && customer_message_content(run_result).length > message_length_limit
  end

  def customer_message_content(run_result)
    response_parts = Captain::Assistant::ResponseParts.from_response(run_result.output)
    response_parts.customer_message_content(citation_urls: @assistant.trusted_citation_urls(run_result))
  end

  def message_length_limit
    @message_length_limit ||= Captain::MessageLengthLimit.for(@conversation)
  end

  def error_response(error)
    handoff_signal_response(
      reasoning: "Error occurred: #{error.message}",
      error_reason: error.class.name.underscore.tr('/', '_')
    )
  end

  def handoff_signal_response(reasoning:, error_reason: nil)
    response = {
      'response' => HANDOFF_SIGNAL,
      'response_parts' => [{ 'text' => HANDOFF_SIGNAL, 'citation_indexes' => [] }],
      'reasoning' => reasoning,
      'handoff_tool_called' => @handoff_tool_called
    }
    return response if error_reason.blank?

    response.merge('error' => true, 'error_reason' => error_reason)
  end
end
