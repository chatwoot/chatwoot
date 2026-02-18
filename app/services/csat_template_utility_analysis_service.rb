class CsatTemplateUtilityAnalysisService
  include CsatTemplateUtilityRubric

  DISCLAIMER = 'Chatwoot submits as Utility, but Meta may reclassify based on content.'.freeze

  pattr_initialize [:account!, :inbox!, :message!, { button_text: nil, language: 'en', context: nil }]

  def perform
    baseline = rule_based_result
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
      context: context,
      baseline: baseline
    ).perform

    return nil if llm_output[:error]

    normalized_output = normalize_llm_score(llm_output, baseline: baseline)
    normalized_output.merge(disclaimer: DISCLAIMER, source: 'captain')
  rescue StandardError => e
    Rails.logger.error("CSAT utility LLM analysis failed for inbox #{inbox.id}: #{e.message}")
    nil
  end

  def normalize_llm_score(result, baseline:)
    classification = result[:classification].to_s
    score = result[:score].to_i.clamp(0, 10)
    baseline_score = baseline[:score].to_i.clamp(0, 10)

    normalized_score =
      case classification
      when 'LIKELY_MARKETING'
        [score, 4, baseline_score].min
      when 'LIKELY_UTILITY'
        [score, 6, baseline_score].max
      else
        score.clamp(4, 6)
      end

    result.merge(score: normalized_score)
  end

  private :normalize_llm_score

  def rule_based_result
    text = sanitized_message
    marketing_hits_count = MARKETING_PATTERNS.count { |pattern| pattern.match?(text) }
    utility_hits_count = UTILITY_PATTERNS.count { |pattern| pattern.match?(text) }
    criteria = evaluate_criteria(text: text, marketing_hits_count: marketing_hits_count)
    score = score_for(criteria)

    classification = classify(criteria: criteria, utility_hits_count: utility_hits_count)
    positive_points = positive_points_for(criteria)
    non_compliance_points = non_compliance_points_for(criteria)
    build_rule_payload(
      classification: classification,
      score: score,
      confidence: confidence_for(classification, marketing_hits_count: marketing_hits_count, utility_hits_count: utility_hits_count),
      positive_points: positive_points,
      non_compliance_points: non_compliance_points,
      score_justification: score_justification_for(score, criteria: criteria),
      criteria: criteria
    )
  end

  def build_rule_payload(payload)
    {
      classification: payload[:classification],
      score: payload[:score],
      confidence: payload[:confidence],
      reasons: reasons_for(
        payload[:classification],
        positive_points: payload[:positive_points],
        non_compliance_points: payload[:non_compliance_points]
      ),
      positive_points: payload[:positive_points],
      non_compliance_points: payload[:non_compliance_points],
      score_justification: payload[:score_justification],
      criteria: payload[:criteria],
      optimized_message: optimized_message_for(payload[:classification]),
      disclaimer: DISCLAIMER,
      source: 'rules'
    }
  end

  private :build_rule_payload

  def sanitized_message
    message.to_s.squish
  end

  def classify(criteria:, utility_hits_count:)
    return 'LIKELY_MARKETING' unless criteria[:marketing_prohibition]
    return 'LIKELY_MARKETING' unless criteria[:prohibited_content]
    return 'LIKELY_UTILITY' if criteria.values.all? && utility_hits_count >= 2

    'UNCLEAR'
  end

  def score_for(criteria)
    score = 0
    score += 2 if criteria[:trigger]
    score += 2 if criteria[:transactional_content]
    score += 2 if criteria[:clarity_and_utility]
    score += 2 if criteria[:marketing_prohibition]
    score += 2 if criteria[:prohibited_content]
    score
  end

  def confidence_for(classification, marketing_hits_count:, utility_hits_count:)
    return 'HIGH' if classification == 'LIKELY_MARKETING' && marketing_hits_count >= 2
    return 'HIGH' if classification == 'LIKELY_UTILITY' && utility_hits_count >= 3
    return 'LOW' if classification == 'UNCLEAR'

    'MEDIUM'
  end

  def reasons_for(classification, positive_points:, non_compliance_points:)
    return non_compliance_points.first(2) if classification == 'LIKELY_MARKETING'
    return positive_points.first(2) if classification == 'LIKELY_UTILITY'

    non_compliance_points.first(2).presence || positive_points.first(2)
  end

  def optimized_message_for(classification)
    return sanitized_message if classification == 'LIKELY_UTILITY'

    build_input_aware_utility_message
  end
end
