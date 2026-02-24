# rubocop:disable Metrics/ModuleLength
module CsatTemplateUtilityRubric
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
    }
  }.freeze

  MARKETING_PATTERNS = [
    /\b(discounts?|offers?|promos?|promotions?|deals?|sales?|buy|shop|subscribe)\b/i,
    /\b(limited\s*time|don't\s*miss|exclusive|special\s*offer)\b/i,
    /\b(click\s*(here|below)\s*to\s*(buy|get|shop))\b/i,
    /\b(new\s*(plans?|products?|services?))\b/i
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
    has_actionable_next_step = text.match?(/\b(reply\s+to\s+this\s+message)\b/i) ||
                               text.match?(/\b(if\s+you\s+still\s+need\s+help)\b/i) ||
                               text.match?(/\b(rate\s+this\s+(support|interaction|conversation))\b/i)
    has_support_context && has_actionable_next_step
  end
end
# rubocop:enable Metrics/ModuleLength
