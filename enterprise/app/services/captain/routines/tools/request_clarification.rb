class Captain::Routines::Tools::RequestClarification < Captain::Routines::Tools::Base
  description 'Record a blocking administrator question when different answers would materially change the Routine'
  param :id, type: 'string', desc: 'Stable snake_case question identifier'
  param :question, type: 'string', desc: 'One focused business-facing question'
  param :reason, type: 'string', desc: 'Why the answer materially changes the Routine'
  param :suggested_answers_json,
        type: 'string',
        required: false,
        desc: 'Optional JSON array of objects with label and answer strings'

  def name = 'request_clarification'

  def perform(tool_context, id:, question:, reason:, suggested_answers_json: nil)
    return invalid_reference(id) unless id.match?(REFERENCE_PATTERN)

    clarification = {
      'id' => id,
      'question' => question,
      'reason' => reason,
      'suggested_answers' => parse_suggested_answers(suggested_answers_json)
    }
    requests = tool_context.state[:clarification_requests] ||= []
    requests.reject! { |request| request['id'] == id }
    requests << clarification

    { status: 'recorded', clarification: clarification }.to_json
  rescue JSON::ParserError
    { status: 'invalid_suggested_answers', message: 'suggested_answers_json must be valid JSON.' }.to_json
  end

  private

  def parse_suggested_answers(value)
    return [] if value.blank?

    suggestions = JSON.parse(value)
    raise JSON::ParserError, 'suggested answers must be an array' unless suggestions.is_a?(Array)

    suggestions.first(5).map do |suggestion|
      next { 'label' => suggestion.to_s, 'answer' => suggestion.to_s } unless suggestion.is_a?(Hash)

      label = suggestion['label'].presence || suggestion['answer'].to_s
      answer = suggestion['answer'].presence || label
      { 'label' => label, 'answer' => answer }
    end
  end
end
