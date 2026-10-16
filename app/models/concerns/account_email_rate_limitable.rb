module AccountEmailRateLimitable
  extend ActiveSupport::Concern

  OUTBOUND_EMAIL_TTL = 25.hours.to_i
  EMAIL_LIMIT_CONFIG_KEY = 'ACCOUNT_EMAILS_LIMIT'.freeze

  def email_rate_limit
    account_limit || global_limit || default_limit
  end

  def emails_sent_today
    Redis::Alfred.get(email_count_cache_key).to_i
  end

  def email_transcript_enabled?
    true
  end

  def within_email_rate_limit?
    return true unless ChatwootApp.chatwoot_cloud?
    return true if emails_sent_today < email_rate_limit

    log_email_limit_reached
    false
  end

  def increment_email_sent_count
    Redis::Alfred.incr(email_count_cache_key).tap do |count|
      Redis::Alfred.expire(email_count_cache_key, OUTBOUND_EMAIL_TTL) if count == 1
    end
  end

  def reserve_email_send_capacity(count = 1)
    return true unless ChatwootApp.chatwoot_cloud?

    loop do
      reservation = attempt_email_capacity_reservation(count)
      if reservation == :limit_exceeded
        log_email_limit_reached
        return false
      end
      return true if reservation.present?
    end
  end

  private

  def attempt_email_capacity_reservation(count)
    Redis::Alfred.with do |redis|
      redis.watch(email_count_cache_key) do
        current_count = redis.get(email_count_cache_key).to_i
        if current_count + count > email_rate_limit
          redis.unwatch
          next :limit_exceeded
        end

        redis.multi do |transaction|
          transaction.incrby(email_count_cache_key, count)
          transaction.expire(email_count_cache_key, OUTBOUND_EMAIL_TTL) if current_count.zero?
        end
      end
    end
  end

  def log_email_limit_reached
    Rails.logger.warn("Account #{id} reached daily email rate limit of #{email_rate_limit}. Sent: #{emails_sent_today}")
  end

  def email_count_cache_key
    @email_count_cache_key ||= format(
      Redis::Alfred::ACCOUNT_OUTBOUND_EMAIL_COUNT_KEY,
      account_id: id,
      date: Time.zone.today.to_s
    )
  end

  def account_limit
    self[:limits]&.dig('emails')&.to_i
  end

  def global_limit
    GlobalConfig.get(EMAIL_LIMIT_CONFIG_KEY)[EMAIL_LIMIT_CONFIG_KEY]&.to_i
  end

  def default_limit
    ChatwootApp.max_limit.to_i
  end
end
