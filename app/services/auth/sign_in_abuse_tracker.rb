class Auth::SignInAbuseTracker
  pattr_initialize [:ip!]

  WINDOW = 24.hours
  BLOCK_TTL = 24.hours
  DEFAULT_THRESHOLD = 5

  def record_failure(email)
    return unless enabled?
    return if trusted_ip? || email.blank?

    now = Time.zone.now.to_i
    Redis::Alfred.zadd(zset_key, now, digest(email))
    Redis::Alfred.zremrangebyscore(zset_key, 0, now - WINDOW.to_i)
    Redis::Alfred.expire(zset_key, WINDOW.to_i)
    block! if Redis::Alfred.zcard(zset_key) >= threshold
  end

  def blocked?
    return false unless enabled?
    return false if trusted_ip?

    Redis::Alfred.get(block_key).present?
  end

  private

  def block!
    return unless Redis::Alfred.set(block_key, Time.zone.now.to_i, nx: true, ex: BLOCK_TTL.to_i)

    Rails.logger.warn(
      "[AuthAbuse][IPBlocked] remote_ip: #{ip}, distinct_failed_emails: #{Redis::Alfred.zcard(zset_key)}, " \
      "window_hours: #{WINDOW.in_hours.to_i}"
    )
  end

  def enabled?
    default = ChatwootApp.chatwoot_cloud? ? 'true' : 'false'
    ActiveModel::Type::Boolean.new.cast(GlobalConfigService.load('AUTH_ABUSE_IP_BLOCKING_ENABLED', default))
  end

  def threshold
    GlobalConfigService.load('AUTH_ABUSE_MAX_DISTINCT_FAILED_EMAILS', DEFAULT_THRESHOLD).to_i
  end

  def trusted_ip?
    return true if ip.blank?

    ['127.0.0.1', '::1'].include?(ip) || allowed_ips.include?(ip)
  end

  def allowed_ips
    ENV.fetch('RACK_ATTACK_ALLOWED_IPS', '').split(',').map(&:strip)
  end

  def digest(email)
    Digest::SHA256.hexdigest(email.to_s.strip.downcase)
  end

  def zset_key
    format(Redis::RedisKeys::AUTH_FAILED_EMAILS_PER_IP, ip: ip)
  end

  def block_key
    format(Redis::RedisKeys::AUTH_ABUSE_BLOCKED_IP, ip: ip)
  end
end
