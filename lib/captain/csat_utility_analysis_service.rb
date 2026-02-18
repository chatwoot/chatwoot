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

    core_result(parsed)
  end

  def core_result(parsed)
    {
      classification: normalize_classification(parsed['classification']),
      optimized_message: parsed['optimized_message'].presence || baseline[:optimized_message]
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
      'baseline_classification' => baseline[:classification].to_s
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

  def event_name
    'csat_utility_analysis'
  end
end
