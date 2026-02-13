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
    return true if emails_sent_today < email_rate_limit

    Rails.logger.warn("Account #{id} reached daily email rate limit of #{email_rate_limit}. Sent: #{emails_sent_today}")
    false
  end

  def increment_email_sent_count
    Redis::Alfred.incr(email_count_cache_key).tap do |count|
      Redis::Alfred.expire(email_count_cache_key, OUTBOUND_EMAIL_TTL) if count == 1
    end
  end

  private

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
