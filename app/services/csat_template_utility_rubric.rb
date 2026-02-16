# rubocop:disable Metrics/ModuleLength
module CsatTemplateUtilityRubric
  extend ActiveSupport::Concern

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

  TRANSACTION_TRIGGER_PATTERNS = [
    /\b(closed|closing|resolved|completed)\b/i,
    /\b(ticket|request|case|conversation|support)\b/i
  ].freeze

  TRANSACTIONAL_CONTENT_PATTERNS = [
    /\b(ticket|request|case|conversation)\b/i,
    /\b(reply\s+to\s+this\s+message|if\s+you\s+still\s+need\s+help)\b/i,
    /\b(rate|califica|calificar)\b/i
  ].freeze

  PROHIBITED_CONTENT_PATTERNS = [
    /\b(contest|sweepstake|lottery|quiz)\b/i,
    /\b(password|otp|pin|cvv|credit\s*card)\b/i,
    /\b(weapon|drugs|gambling)\b/i
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

  private

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

  def evaluate_criteria(text:, marketing_hits_count:)
    {
      trigger: TRANSACTION_TRIGGER_PATTERNS.any? { |pattern| pattern.match?(text) },
      transactional_content: TRANSACTIONAL_CONTENT_PATTERNS.count { |pattern| pattern.match?(text) } >= 2,
      marketing_prohibition: marketing_hits_count.zero?,
      prohibited_content: PROHIBITED_CONTENT_PATTERNS.none? { |pattern| pattern.match?(text) },
      clarity_and_utility: clear_utility_intent?(text)
    }
  end

  def clear_utility_intent?(text)
    has_support_context = text.match?(/\b(support|ticket|request|case|conversation)\b/i)
    has_actionable_next_step = text.match?(/\b(reply|rate|califica|calificar)\b/i)
    has_support_context && has_actionable_next_step
  end

  def positive_points_for(criteria)
    points = []
    points << 'The message clearly references a support interaction lifecycle event.' if criteria[:trigger]
    points << 'The message content is transactional and relevant to an existing support interaction.' if criteria[:transactional_content]
    points << 'No promotional wording was detected.' if criteria[:marketing_prohibition]
    points << 'No prohibited or sensitive-request content was detected.' if criteria[:prohibited_content]
    points << 'The user can clearly understand why they received this message and what to do next.' if criteria[:clarity_and_utility]
    points
  end

  def non_compliance_points_for(criteria)
    points = []
    points << 'Trigger context is not explicit enough (for example, support request closed/resolved).' unless criteria[:trigger]
    points << 'Transactional details are insufficient or too generic for utility classification.' unless criteria[:transactional_content]
    points << 'Promotional wording may cause Meta to classify this as Marketing.' unless criteria[:marketing_prohibition]
    points << 'Content may include prohibited or sensitive-request indicators.' unless criteria[:prohibited_content]
    points << 'Utility intent is unclear; the message should be more direct and support-focused.' unless criteria[:clarity_and_utility]
    points
  end

  def score_justification_for(score, criteria:)
    if score >= 9 && criteria.values.all?
      'High utility fit: transactional trigger is clear, wording is non-promotional, and intent is support-focused.'
    elsif score >= 6
      'Moderate utility fit: message has utility signals but needs clearer transactional framing or less ambiguous wording.'
    else
      'Low utility fit: message lacks clear transactional utility context or includes language that may be treated as Marketing.'
    end
  end
end
# rubocop:enable Metrics/ModuleLength
