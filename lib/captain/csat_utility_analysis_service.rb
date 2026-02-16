class Captain::CsatUtilityAnalysisService < Captain::BaseTaskService
  pattr_initialize [:account!, :message!, { button_text: nil, language: 'en', context: nil, baseline: {} }]

  def perform
    api_response = make_api_call(
      model: GPT_MODEL,
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: message }
      ]
    )

    return api_response if api_response[:error]

    build_result(api_response[:message])
  end

  private

  def build_result(response_message)
    parsed = parse_json_response(response_message)
    return { error: 'Invalid LLM response format' } if parsed.blank?

    core_result(parsed).merge(rubric_result(parsed))
  end

  def core_result(parsed)
    {
      classification: normalize_classification(parsed['classification']),
      score: parsed['score'].to_i.clamp(0, 10),
      confidence: normalize_confidence(parsed['confidence']),
      reasons: Array(parsed['reasons']).compact.first(4),
      optimized_message: parsed['optimized_message'].presence || baseline[:optimized_message]
    }
  end

  def rubric_result(parsed)
    {
      positive_points: Array(parsed['positive_points']).compact.first(5),
      non_compliance_points: Array(parsed['non_compliance_points']).compact.first(5),
      score_justification: parsed['score_justification'].to_s,
      criteria: normalize_criteria(parsed['criteria'])
    }
  end

  def system_prompt
    template = prompt_from_file('csat_utility_analysis')
    Liquid::Template.parse(template).render(prompt_variables)
  end

  def prompt_variables
    {
      'message' => message.to_s,
      'button_text' => button_text.to_s,
      'language' => language.to_s,
      'context' => context.to_s,
      'baseline_classification' => baseline[:classification].to_s,
      'baseline_score' => baseline[:score].to_s,
      'baseline_reasons' => Array(baseline[:reasons]).join('; ')
    }
  end

  def parse_json_response(content)
    raw = content.to_s.strip
    json = raw.match(/```json\s*(.*?)\s*```/m)&.captures&.first || raw
    JSON.parse(json)
  rescue JSON::ParserError
    nil
  end

  def normalize_classification(value)
    normalized = value.to_s.upcase
    return normalized if %w[LIKELY_UTILITY LIKELY_MARKETING UNCLEAR].include?(normalized)

    baseline[:classification].presence || 'UNCLEAR'
  end

  def normalize_confidence(value)
    normalized = value.to_s.upcase
    return normalized if %w[HIGH MEDIUM LOW].include?(normalized)

    'MEDIUM'
  end

  def normalize_criteria(value)
    data = value.is_a?(Hash) ? value : {}

    {
      trigger: to_boolean(data['trigger'], fallback: baseline.dig(:criteria, :trigger)),
      transactional_content: to_boolean(data['transactional_content'], fallback: baseline.dig(:criteria, :transactional_content)),
      marketing_prohibition: to_boolean(data['marketing_prohibition'], fallback: baseline.dig(:criteria, :marketing_prohibition)),
      prohibited_content: to_boolean(data['prohibited_content'], fallback: baseline.dig(:criteria, :prohibited_content)),
      clarity_and_utility: to_boolean(data['clarity_and_utility'], fallback: baseline.dig(:criteria, :clarity_and_utility))
    }
  end

  def to_boolean(value, fallback:)
    return true if value == true
    return false if value == false

    fallback == true
  end

  def event_name
    'csat_utility_analysis'
  end
end
