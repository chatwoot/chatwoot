class CsatTemplateUtilityAnalysisService
  include CsatTemplateUtilityRubric

  pattr_initialize [:account!, :inbox!, :message!, { button_text: nil, language: 'en' }]

  def perform
    baseline = rule_based_result
    return baseline if baseline[:classification] == 'LIKELY_MARKETING'

    llm_result = llm_result_or_nil(baseline)
    llm_result || baseline
  end

  private

  def llm_result_or_nil(baseline)
    llm_output = Captain::CsatUtilityAnalysisService.new(
      account: account,
      message: message,
      button_text: button_text,
      language: language,
      baseline: baseline
    ).perform

    return nil if llm_output[:error]

    normalize_llm_result(llm_output, baseline: baseline)
  rescue StandardError => e
    Rails.logger.error("CSAT utility LLM analysis failed for inbox #{inbox.id}: #{e.message}")
    nil
  end

  def normalize_llm_result(result, baseline:)
    classification = normalized_classification(result[:classification], baseline: baseline)
    optimized_message = result[:optimized_message].presence || baseline[:optimized_message]
    optimized_message = baseline[:optimized_message] if baseline[:classification] == 'LIKELY_MARKETING'

    {
      classification: classification,
      optimized_message: optimized_message
    }
  end

  def normalized_classification(value, baseline:)
    raw = value.to_s
    return 'LIKELY_MARKETING' if baseline[:classification] == 'LIKELY_MARKETING'

    raw
  end

  def rule_based_result
    text = sanitized_message
    marketing_hits_count = MARKETING_PATTERNS.count { |pattern| pattern.match?(text) }
    utility_hits_count = UTILITY_PATTERNS.count { |pattern| pattern.match?(text) }
    criteria = evaluate_criteria(text: text, marketing_hits_count: marketing_hits_count)
    classification = classify(criteria: criteria, utility_hits_count: utility_hits_count)
    build_rule_payload(
      classification: classification
    )
  end

  def build_rule_payload(payload)
    {
      classification: payload[:classification],
      optimized_message: optimized_message_for(payload[:classification])
    }
  end

  def sanitized_message
    message.to_s.squish
  end

  def classify(criteria:, utility_hits_count:)
    return 'LIKELY_MARKETING' unless criteria[:marketing_prohibition]
    return 'LIKELY_MARKETING' unless criteria[:prohibited_content]
    return 'LIKELY_UTILITY' if criteria.values.all? && utility_hits_count >= 2

    'UNCLEAR'
  end

  def optimized_message_for(classification)
    return sanitized_message if classification == 'LIKELY_UTILITY'

    build_input_aware_utility_message
  end
end
