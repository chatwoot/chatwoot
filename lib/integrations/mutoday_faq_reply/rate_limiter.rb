class Integrations::MutodayFaqReply::RateLimiter
  pattr_initialize [:conversation!]

  # These are not cost controls. Each one contains a single failure: a bug that makes the
  # bot answer its own output and machine-gun a real customer's phone. They are set far
  # above peak so normal operation never touches them, and a trip is a defect report.
  #
  # The once-per-conversation limit is not here — it is the Redis marker the eligibility
  # gate claims, which has to be atomic for a different reason.
  #
  # The contact limit is 12/hour rather than 3. With lock_to_single_conversation off, every
  # agent resolve means the customer's next message opens a new conversation and earns a
  # new reply, so a student asking four questions in an hour would have tripped a limit of
  # three during ordinary use.
  LIMITS = {
    contact_hour: { limit: 12, ttl: 1.hour.to_i },
    inbox_hour: { limit: 60, ttl: 1.hour.to_i },
    inbox_day: { limit: 500, ttl: 25.hours.to_i }
  }.freeze

  CONTACT_HOUR_KEY = 'MUTODAY_FAQ_REPLY::CONTACT::%<contact_id>d::%<bucket>s'.freeze
  INBOX_HOUR_KEY = 'MUTODAY_FAQ_REPLY::INBOX::%<inbox_id>d::%<bucket>s'.freeze
  INBOX_DAY_KEY = 'MUTODAY_FAQ_REPLY::INBOX_DAY::%<inbox_id>d::%<bucket>s'.freeze

  # A WATCH aborts whenever another worker touches the same key between the read and the
  # write, which on a shared inbox-hour key is ordinary traffic rather than a breach.
  MAX_CONTENTION_ATTEMPTS = 3

  # Reserved before the message row is created: Message#send_reply enqueues SendReplyJob
  # unconditionally for every message and there is no pre-send hook, so this is the only
  # place a limit can be enforced.
  #
  # nil when every scope had capacity. Otherwise a Hash naming what stopped it. A scope
  # that reserved before a later one refused keeps its increment — a trip means something
  # is already broken, and unwinding it would need a second round of writes to fix a
  # count that nothing reads except these limits.
  def reserve
    LIMITS.each do |scope, config|
      next if attempt(scope, config)

      return { outcome: 'refused_rate_limit', scope: scope.to_s, limit: config[:limit] }
    end

    nil
  rescue Redis::BaseError => e
    { outcome: 'failed', stage: 'redis', error: e.class.name }
  end

  private

  def attempt(scope, config)
    key = key_for(scope)

    MAX_CONTENTION_ATTEMPTS.times do
      case reserve_once(key, config[:limit], config[:ttl])
      when :ok then return true
      when :limited then return false
      end
    end

    # Every attempt lost the compare-and-set to ordinary concurrency, never to a breach.
    # A breaker set five times above peak can afford to lose one increment; withholding a
    # customer's reply because two workers touched the same counter cannot be right.
    Rails.logger.info("[mutoday_faq_reply] outcome=rate_limit_contended scope=#{scope} conversation_id=#{conversation.id}")
    true
  end

  # :ok reserved · :limited the scope is full · :contended the WATCH aborted, so this says
  # nothing about capacity and the caller tries again. Conflating the last two would page
  # Sentry and suppress a customer's reply over ordinary concurrency.
  def reserve_once(key, limit, ttl)
    Redis::Alfred.with do |redis|
      redis.watch(key) do
        current = redis.get(key).to_i
        if current + 1 > limit
          redis.unwatch
          next :limited
        end

        applied = redis.multi do |transaction|
          transaction.incr(key)
          transaction.expire(key, ttl) if current.zero?
        end
        applied.present? ? :ok : :contended
      end
    end
  end

  def key_for(scope)
    case scope
    when :contact_hour then format(CONTACT_HOUR_KEY, contact_id: conversation.contact_id, bucket: hour_bucket)
    when :inbox_hour then format(INBOX_HOUR_KEY, inbox_id: conversation.inbox_id, bucket: hour_bucket)
    when :inbox_day then format(INBOX_DAY_KEY, inbox_id: conversation.inbox_id, bucket: day_bucket)
    end
  end

  # App zone on purpose. These are engineering circuit breakers, not business-day counters,
  # and a bucket boundary at 07:00 Bangkok is irrelevant to detecting a loop.
  def hour_bucket
    Time.current.strftime('%Y%m%d%H')
  end

  def day_bucket
    Time.current.strftime('%Y%m%d')
  end
end
