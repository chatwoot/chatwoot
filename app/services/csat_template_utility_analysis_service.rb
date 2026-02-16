class CsatTemplateUtilityAnalysisService
  DISCLAIMER = 'Chatwoot submits as Utility, but Meta may reclassify based on content.'.freeze
  LANGUAGE_FALLBACKS = {
    'en' => {
      support_request: 'support request',
      support_ticket: 'support ticket',
      support_conversation: 'support conversation',
      status_closed: 'closed',
      status_resolved: 'resolved',
      status_completed: 'completed',
      line_status: 'Your %<subject>s has been %<status>s.',
      line_help: 'If you still need help, simply reply to this message.',
      line_rate: 'To rate this support interaction, please use the button below.'
    },
    'es' => {
      support_request: 'solicitud de soporte',
      support_ticket: 'ticket de soporte',
      support_conversation: 'conversación de soporte',
      status_closed: 'cerrada',
      status_resolved: 'resuelta',
      status_completed: 'completada',
      line_status: 'Tu %<subject>s ha sido %<status>s.',
      line_help: 'Si aún necesitas ayuda, responde a este mensaje.',
      line_rate: 'Para calificar esta interacción de soporte, usa el botón de abajo.'
    }
  }.freeze

  MARKETING_PATTERNS = [
    /\b(discount|offer|promo|promotion|deal|sale|buy|shop|subscribe)\b/i,
    /\b(limited\s*time|don't\s*miss|exclusive|special\s*offer)\b/i,
    /\b(click\s*(here|below)\s*to\s*(buy|get|shop))\b/i,
    /\b(new\s*(plan|product|service))\b/i
  ].freeze

  STATUS_PATTERNS = {
    'closed' => /\b(closed|closing)\b/i,
    'resolved' => /\b(resolved|resolve[sd]?)\b/i,
    'completed' => /\b(completed|complete[sd]?)\b/i
  }.freeze

  SUBJECT_PATTERNS = {
    'support ticket' => /\b(ticket)\b/i,
    'support conversation' => /\b(conversation|chat)\b/i,
    'support request' => /\b(request|case|support)\b/i
  }.freeze

  UTILITY_PATTERNS = [
    /\b(support|ticket|request|conversation|case)\b/i,
    /\b(closed|resolved|completed)\b/i,
    /\b(reply\s+to\s+this\s+message\b)/i,
    /\b(if\s+you\s+still\s+need\s+help)\b/i,
    /\b(rate\s+this\s+(support|interaction|conversation))\b/i
  ].freeze

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

    llm_output.merge(disclaimer: DISCLAIMER, source: 'captain')
  rescue StandardError => e
    Rails.logger.error("CSAT utility LLM analysis failed for inbox #{inbox.id}: #{e.message}")
    nil
  end

  def rule_based_result
    text = sanitized_message
    marketing_hits_count = MARKETING_PATTERNS.count { |pattern| pattern.match?(text) }
    utility_hits_count = UTILITY_PATTERNS.count { |pattern| pattern.match?(text) }

    classification = classify(marketing_hits_count: marketing_hits_count, utility_hits_count: utility_hits_count)
    {
      classification: classification,
      score: score_for(classification, marketing_hits_count: marketing_hits_count, utility_hits_count: utility_hits_count),
      confidence: confidence_for(classification, marketing_hits_count: marketing_hits_count, utility_hits_count: utility_hits_count),
      reasons: reasons_for(classification),
      optimized_message: optimized_message_for(classification),
      disclaimer: DISCLAIMER,
      source: 'rules'
    }
  end

  def sanitized_message
    message.to_s.squish
  end

  def classify(marketing_hits_count:, utility_hits_count:)
    return 'LIKELY_MARKETING' if marketing_hits_count.positive?
    return 'LIKELY_UTILITY' if utility_hits_count >= 2

    'UNCLEAR'
  end

  def score_for(classification, marketing_hits_count:, utility_hits_count:)
    return [3 - marketing_hits_count, 0].max if classification == 'LIKELY_MARKETING'
    return [7 + utility_hits_count, 10].min if classification == 'LIKELY_UTILITY'

    5
  end

  def confidence_for(classification, marketing_hits_count:, utility_hits_count:)
    return 'HIGH' if classification == 'LIKELY_MARKETING' && marketing_hits_count >= 2
    return 'HIGH' if classification == 'LIKELY_UTILITY' && utility_hits_count >= 3
    return 'LOW' if classification == 'UNCLEAR'

    'MEDIUM'
  end

  def reasons_for(classification)
    if classification == 'LIKELY_MARKETING'
      return [
        'Message contains promotional wording that can be interpreted as marketing.',
        'Utility templates should focus only on a support/transactional update and rating request.'
      ]
    end

    if classification == 'LIKELY_UTILITY'
      return [
        'Message is tied to a completed support interaction.',
        'It asks for feedback without promoting new purchases or offers.'
      ]
    end

    [
      'Message intent is not explicit enough for utility-only classification.',
      'Add clear transactional context (support request closed) and avoid ambiguous CTA wording.'
    ]
  end

  def optimized_message_for(classification)
    return sanitized_message if classification == 'LIKELY_UTILITY'

    build_input_aware_utility_message
  end

  def build_input_aware_utility_message
    text = translation_pack
    subject = detected_subject
    status = detected_status
    intro = extracted_intro_sentence

    parts = []
    parts << intro if intro.present?
    parts << format(text[:line_status], subject: subject, status: status)
    parts << text[:line_help]
    parts << text[:line_rate]
    parts.join(' ')
  end

  def detected_status
    matched = STATUS_PATTERNS.find { |_key, pattern| pattern.match?(sanitized_message) }
    status_key = matched&.first || 'closed'
    translation_pack[:"status_#{status_key}"]
  end

  def detected_subject
    matched = SUBJECT_PATTERNS.find { |_key, pattern| pattern.match?(sanitized_message) }
    subject_key = matched&.first&.tr(' ', '_') || 'support_request'
    translation_pack[subject_key.to_sym]
  end

  def extracted_intro_sentence
    first_sentence = sanitized_message.split(/(?<=[.!?])\s+/).first.to_s
    return nil if first_sentence.blank?
    return nil if MARKETING_PATTERNS.any? { |pattern| pattern.match?(first_sentence) }
    return nil unless first_sentence.match?(/\b(thanks|thank you|hello|hi)\b/i)

    normalized = first_sentence.gsub(/\s+/, ' ').strip
    normalized.ends_with?('.', '!', '?') ? normalized : "#{normalized}."
  end

  def translation_pack
    LANGUAGE_FALLBACKS.fetch(primary_language_code, LANGUAGE_FALLBACKS['en'])
  end

  def primary_language_code
    language.to_s.downcase.split(/[-_]/).first
  end
end
