class Integrations::MutodayFaqReply::Telemetry
  TAG = '[mutoday_faq_reply]'.freeze

  # Closed set. skipped means nothing needed doing; failed means we could not do it. Having
  # two words is the whole point — one of them is a normal Tuesday and the other is a bug.
  OUTCOMES = %w[replied skipped refused_rate_limit misconfigured failed].freeze

  # Closed set, one per guard in the eligibility gate.
  GUARDS = %w[
    not_incoming no_source_id not_contact_sender not_line_inbox mode_off
    already_answered foreign_template noise_deferred already_claimed
  ].freeze

  UNKNOWN = 'unknown'.freeze

  # The entire vocabulary of a log line, in print order. There is deliberately no key
  # through which the customer's message, an FAQ answer, a contact name or a LINE userId
  # could pass: a segment, an outcome and a route are facts about our own routing, but the
  # text belongs to the person who typed it. Anything not on this list is dropped.
  FIELDS = %i[
    outcome guard route result stage scope limit error
    mode shadow conversation_id inbox_id contact_id
    faq_id confidence deny_topic latency_ms
  ].freeze

  ALERT_KEY = 'MUTODAY_FAQ_REPLY::ALERT::%<kind>s'.freeze
  ALERT_TTL = 15.minutes.to_i

  class << self
    # One structured line per job, always. Never raises: the reply path has already fallen
    # back once by the time most of these are written, and a failed log line must not turn
    # that into silence.
    def log(**fields)
      known, dropped = partition(fields)
      Rails.logger.warn("#{TAG} outcome=failed stage=telemetry dropped_fields=#{dropped.join(',')}") if dropped.any?
      Rails.logger.info("#{TAG} #{render(known)}")
    rescue StandardError => e
      swallow(e)
    end

    # Sentry plus an error log, through the app's own tracker. `kind` is the dedup slot: one
    # alert per kind per 15 minutes, so a noisy kind cannot swallow another kind's first
    # alert. Pass kind: nil for the failures that are always ours to fix — a bad API token
    # and an unknown model id are deploy bugs, and every occurrence should page.
    def alert(error, account:, kind: nil)
      return unless kind.nil? || claim_alert_slot(kind)

      ChatwootExceptionTracker.new(error, account: account).capture_exception
    rescue StandardError => e
      swallow(e)
    end

    private

    def partition(fields)
      known = FIELDS.each_with_object({}) do |field, memo|
        value = fields[field]
        memo[field] = value unless value.nil?
      end
      [known, fields.keys - FIELDS]
    end

    def render(fields)
      fields.map { |key, value| "#{key}=#{sanitise(key, value)}" }.join(' ')
    end

    # An out-of-set label is a programming mistake on our side, not customer content, so it
    # is safe to name — but it is not allowed to masquerade as a valid one.
    def sanitise(key, value)
      case key
      when :outcome then OUTCOMES.include?(value.to_s) ? value : "#{UNKNOWN}(#{value})"
      when :guard then GUARDS.include?(value.to_s) ? value : "#{UNKNOWN}(#{value})"
      else value
      end
    end

    def claim_alert_slot(kind)
      Redis::Alfred.set(format(ALERT_KEY, kind: kind), '1', nx: true, ex: ALERT_TTL).present?
    end

    def swallow(error)
      Rails.logger.error("#{TAG} outcome=failed stage=telemetry error=#{error.class}")
    rescue StandardError
      nil
    end
  end
end
