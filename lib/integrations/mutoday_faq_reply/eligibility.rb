class Integrations::MutodayFaqReply::Eligibility
  pattr_initialize [:message!, :hook!]

  # Our own keys. lib/redis/redis_keys.rb is upstream and stays untouched.
  MARKER_KEY = 'MUTODAY_FAQ_REPLY::CONVERSATION::%<conversation_id>d'.freeze
  DEFER_KEY = 'MUTODAY_FAQ_REPLY::DEFER::%<conversation_id>d'.freeze
  MARKER_TTL = 24.hours.to_i
  DEFER_TTL = 24.hours.to_i

  # Thai LINE users greet first and ask second. Replying to "สวัสดีครับ" would burn the one
  # reply this conversation gets and leave the actual question unanswered forever, so a
  # message that is only a greeting is deferred: the counter moves, the marker does not,
  # and the next message is treated as the first. After this many deferrals we answer
  # anyway, so a customer who only ever greets is not left in silence.
  MAX_DEFERRALS = 2

  # A message this short carries no question worth classifying.
  MIN_MEANINGFUL_LENGTH = 2

  # rubocop:disable Style/WordArray -- these are Thai greetings, and %w mangles them
  BARE_GREETINGS = [
    'สวัสดี', 'หวัดดี', 'ดีครับ', 'ดีค่ะ', 'ดีคับ', 'สอบถาม', 'ขอสอบถาม',
    'ครับ', 'ค่ะ', 'โอเค', 'hi', 'hello', 'hey'
  ].freeze
  # rubocop:enable Style/WordArray

  # Compared after the same normalisation the deny-list uses, so "สวัสดีครับ" and "สวัสดี"
  # are one form. Matching is exact: "สวัสดีครับ อยากถามเรื่องรับสมัคร" is a real question.
  GREETING_FORMS = BARE_GREETINGS.map { |greeting| Integrations::MutodayFaqReply::DenyList.normalise(greeting) }.uniq.freeze

  delegate :conversation, to: :message

  # nil when the customer should get a reply. Otherwise a Hash naming why not, which the
  # caller logs and — for the two misconfiguration cases — reports.
  def rejection
    return @rejection if defined?(@rejection)

    @rejection = structural_rejection || configuration_rejection || state_rejection
  rescue Redis::BaseError => e
    # C14 — Redis is the only thing the marker and the rate limiter can be built on. If it
    # is unreachable we cannot tell whether we have already replied, so we stay quiet.
    @rejection = { outcome: 'failed', stage: 'redis', error: e.class.name }
  end

  # True when the gate let a greeting through only because it had already been deferred
  # MAX_DEFERRALS times. The caller records it as its own route so the shadow numbers can
  # tell a forced acknowledgment from a real one.
  def noise_forced?
    @noise_forced.present?
  end

  # G8 on its own, so the caller can run it again immediately before writing the message.
  # The gate is evaluated up to eight seconds before the write while the model is thinking,
  # and an agent can answer in that window.
  def already_answered
    blocking = conversation.messages.where(message_type: %i[outgoing template]).order(:id).first
    return nil if blocking.nil?
    return 'already_answered' if blocking.outgoing? || ours?(blocking)

    # A greeting or out-of-office template beat us to it. Both fire synchronously from the
    # inbound message's own after_create_commit while we travel through two queues, so this
    # is not a race we can win — it is a setting that has to be off, and it silences the
    # feature for the life of every conversation until someone notices.
    'foreign_template'
  end

  # G9 — the atomic once-per-conversation claim. A single SET NX EX, so two workers racing
  # on the same conversation cannot both proceed.
  def claim_conversation
    key = format(MARKER_KEY, conversation_id: conversation.id)
    return true if Redis::Alfred.set(key, message.id.to_s, nx: true, ex: MARKER_TTL)

    # A retry of THIS message may proceed — already_answered blocks a retry that follows a
    # successful send. A different message on the same conversation may not.
    Redis::Alfred.get(key) == message.id.to_s
  end

  private

  # G2, G3, G4 — three independent tests that this is a customer speaking on LINE. Any one
  # of them alone would do; together they survive an upstream refactor weakening another.
  def structural_rejection
    return skipped('not_incoming') unless message.incoming?
    return skipped('no_source_id') if message.source_id.blank?
    return skipped('sender_not_contact') unless message.sender.is_a?(Contact)

    nil
  end

  # G5, G6 — the inbox is the wrong one, or the operator has switched us off.
  def configuration_rejection
    return misconfigured('not_line_inbox') unless message.inbox.channel_type == 'Channel::Line'
    return skipped('mode_off') if hook.settings['mode'] == 'off'

    nil
  end

  # G8, G7', G9 — has anyone spoken, is this only a greeting, and can we claim the marker.
  def state_rejection
    answered = already_answered
    return answered == 'foreign_template' ? misconfigured(answered) : skipped(answered) if answered

    return skipped('noise_deferred') if defer_noise?
    return skipped('marker_claimed') unless claim_conversation

    nil
  end

  # Increments first and reads the result, so two greetings arriving together cannot both
  # see the same count. Returns false once the allowance is spent, which lets the greeting
  # through to a plain acknowledgment.
  def defer_noise?
    return false unless noise?

    count = increment_deferrals
    return true if count <= MAX_DEFERRALS

    @noise_forced = true
    false
  end

  def noise?
    return false unless classifiable_text?

    normalised = Integrations::MutodayFaqReply::DenyList.normalise(message.content)
    normalised.length <= MIN_MEANINGFUL_LENGTH || GREETING_FORMS.include?(normalised)
  end

  # A photo, a sticker or a file is a complete attempt to reach us and waiting cannot
  # improve it, so it is never deferred — it gets the acknowledgment immediately.
  def classifiable_text?
    message.content.present? && message.content_type == 'text'
  end

  def increment_deferrals
    key = format(DEFER_KEY, conversation_id: conversation.id)
    count = Redis::Alfred.incr(key)
    Redis::Alfred.expire(key, DEFER_TTL) if count == 1
    count
  end

  def ours?(other_message)
    other_message.additional_attributes.is_a?(Hash) && other_message.additional_attributes.key?('mutoday_faq_reply')
  end

  def skipped(guard)
    { outcome: 'skipped', guard: guard }
  end

  # Reaching one of these means someone bound the hook to the wrong inbox or left a message
  # template switched on. Both are deployment mistakes that silence the feature, and both
  # are reported rather than logged quietly.
  def misconfigured(guard)
    { outcome: 'misconfigured', guard: guard }
  end
end
