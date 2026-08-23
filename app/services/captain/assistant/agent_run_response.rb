module Captain::Assistant::AgentRunResponse
  # Model-internal markers that leak into customer-facing output when the agent
  # fails to produce a clean structured response (seen as raw <tools>/<function>
  # tool-call XML and reasoning text in assistant messages).
  LEAKED_AGENT_INTERNAL_MARKERS = ['<tools>', '<tool_call>', '<function>'].freeze
  private_constant :LEAKED_AGENT_INTERNAL_MARKERS

  private

  def process_agent_result(run_result)
    Rails.logger.info "[Captain V2] Agent result: #{run_result.inspect}"
    structured_response = normalize_model_output(run_result.output)
    response_parts = Captain::Assistant::ResponseParts.from_response(structured_response)
    return leaked_agent_internal_error_response if leaked_agent_internal_content?(response_parts)

    response_parts = response_parts.without_citations unless @assistant.citations_enabled?
    structured_response['response_parts'] = response_parts.to_a
    structured_response['response'] = response_parts.plain_text
    structured_response['agent_name'] = run_result.context&.dig(:current_agent)
    structured_response.merge!(agent_run_flags(run_result))
    structured_response
  end

  # The agents library can return the structured response as a JSON string instead
  # of a Hash. If that string is left as-is, rendering it (e.g. the playground)
  # double-encodes it and the escaped JSON leaks to the caller, so parse it first.
  def normalize_model_output(model_output)
    return model_output.with_indifferent_access if model_output.is_a?(Hash)

    parsed_json = parse_json_string(model_output)
    return parsed_json.with_indifferent_access if parsed_json.is_a?(Hash)

    { 'response' => model_output.to_s, 'reasoning' => 'Processed by agent' }
  end

  def parse_json_string(model_output)
    JSON.parse(model_output)
  rescue JSON::ParserError, TypeError
    nil
  end

  def leaked_agent_internal_content?(response_parts)
    text = response_parts.plain_text
    LEAKED_AGENT_INTERNAL_MARKERS.any? { |marker| text.include?(marker) }
  end

  # Never surface model-internal tool-call/chain-of-thought text to a customer.
  # Treat it as a generation failure so the pipeline hands off instead of posting
  # the raw markup as an assistant message.
  def leaked_agent_internal_error_response
    error_response(StandardError.new('agent_internal_content_leaked'))
  end

  def agent_run_flags(run_result)
    {
      'handoff_tool_called' => run_result.context&.dig(:captain_v2_handoff_tool_called) || false,
      'handoff_offer_pending' => run_result.context&.dig(:captain_v2_handoff_offer_pending) || false
    }
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
    {
      'response' => 'conversation_handoff',
      'response_parts' => [{ 'text' => 'conversation_handoff', 'citation_indexes' => [] }],
      'reasoning' => "Error occurred: #{error.message}",
      'error' => true,
      'error_reason' => error.class.name.underscore.tr('/', '_'),
      'handoff_tool_called' => @handoff_tool_called
    }
  end
end
