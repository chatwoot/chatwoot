class Captain::Conversation::HandoffConsentService
  pattr_initialize [:conversation!, :assistant!]

  # Words/phrases a customer uses to ask for a human up front, without the
  # assistant needing to offer first. Matching is intentionally broad and
  # case-insensitive so a direct request always skips the offer step.
  EXPLICIT_REQUEST_PATTERNS = [
    /human\b/, /real\s+agent/, /\bagent\b/, /representative/, /support\s+(agent|team|staff|person)/,
    /customer\s+(service|support)/, /talk\s+to\s+(someone|a\s+human|a\s+person|an?\s+agent)/,
    /speak\s+to\s+(someone|a\s+human|a\s+person|an?\s+agent)/, /connect\s+me/, /call\s+me/,
    /phone\s+call/, /escalat/, /manager\b/, /live\s+(agent|person|human)/, /someone\s+(real|actual)/
  ].freeze

  # Affirmative replies a customer gives after the assistant has offered a human.
  AFFIRMATIVE_PATTERNS = [
    /\b(yes|yeah|yep|sure|ok|okay|please|fine|good|alright)\b/, /go\s+ahead/,
    /\b(do\s+it|would\s+be\s+great|sounds\s+good|that\s+works|that'?s\s+fine)\b/
  ].freeze

  # Whether the customer has already asked for, or accepted an offer of, human
  # assistance. When false, a handoff request should post an offer and wait for
  # the customer to accept instead of transferring immediately.
  def consented_to_human_help?
    explicit_request? || accepted_recent_offer?
  end

  private

  def explicit_request?
    customer_messages.any? { |content| EXPLICIT_REQUEST_PATTERNS.any? { |pattern| content.match?(pattern) } }
  end

  def accepted_recent_offer?
    return false unless offer_message_exists?
    return false if customer_messages.empty?

    AFFIRMATIVE_PATTERNS.any? { |pattern| customer_messages.last.match?(pattern) }
  end

  def offer_message_exists?
    assistant_messages.any? { |content| offer_phrases.any? { |phrase| content.match?(phrase) } }
  end

  def offer_phrases
    [
      /human\s+agent/i, /speak\s+to\s+a\s+human/i, /talk\s+to\s+(a|another)\s+agent/i,
      /connect\s+you\s+with\s+(a|an?)\s+(human|agent)/i, /talk\s+to\s+(a|an?)\s+(person|human)/i,
      /another\s+(support\s+)?agent/i
    ]
  end

  def customer_messages
    @customer_messages ||= message_contents(message_type: :incoming)
  end

  def assistant_messages
    @assistant_messages ||= message_contents(message_type: :outgoing)
  end

  def message_contents(message_type:)
    conversation.messages
                .where(message_type: message_type, private: false)
                .order(:created_at)
                .pluck(:content)
                .compact
                .map(&:downcase)
  end
end
