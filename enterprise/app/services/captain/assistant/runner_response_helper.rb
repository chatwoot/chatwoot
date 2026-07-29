module Captain::Assistant::RunnerResponseHelper
  private

  def process_agent_result(result)
    Rails.logger.info "[Captain V2] Agent result: #{result.inspect}"
    output = result.output
    response = output.is_a?(Hash) ? output.with_indifferent_access : { 'response' => output.to_s, 'reasoning' => 'Processed by agent' }
    response_parts = Captain::Assistant::ResponseParts.from_response(response)
    response_parts = response_parts.without_citations unless @assistant.config['feature_citation']
    response['response_parts'] = response_parts.to_a
    response['response'] = response_parts.plain_text
    response['agent_name'] = result.context&.dig(:current_agent)
    response['handoff_tool_called'] = result.context&.dig(:captain_v2_handoff_tool_called) || false
    response
  end

  def rewrite_oversized_response(result)
    response_rewriter.rewrite(result, response: response_text(result), limit: message_length_limit)
  end

  def response_rewriter
    @response_rewriter ||= Captain::Assistant::ResponseRewriter.new(
      assistant: @assistant,
      attribute_provider: Captain::Assistant::InstrumentationAttributeProvider.new(self)
    )
  end

  def record_turn_start(result)
    history = Array(result.context&.dig(:conversation_history))
    turn_start_index = history.rindex { |message| message[:role].to_s == 'user' }
    result.context[:captain_v2_turn_start_index] = turn_start_index if turn_start_index
  end

  def response_too_long?(result)
    message_length_limit && response_text(result).length > message_length_limit
  end

  def response_text(result)
    extract_text_from_content(result.output).to_s
  end

  def message_length_limit
    @message_length_limit ||= Captain::MessageLengthLimit.for(@conversation)
  end

  def error_response(error_message)
    {
      'response' => 'conversation_handoff',
      'response_parts' => [{ 'text' => 'conversation_handoff', 'citation_indexes' => [] }],
      'reasoning' => "Error occurred: #{error_message}",
      'handoff_tool_called' => @handoff_tool_called
    }
  end
end
