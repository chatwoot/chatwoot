class DeviceVerification::ChallengeService
  pattr_initialize [:user!, :request_meta]

  CODE_TTL = 10.minutes
  MAX_ATTEMPTS = 5
  ISSUANCE_LIMIT = 10
  ISSUANCE_WINDOW = 24.hours

  def issue!
    return nil unless issuance_allowed?

    jti = SecureRandom.hex(8)
    code = format('%06d', SecureRandom.random_number(10**6))
    ::Redis::Alfred.setex(self.class.code_key(user, jti), self.class.digest_for(code, jti), CODE_TTL)
    Enterprise::DeviceVerificationMailer.verification_code(user, DeviceVerification.encrypt_code(code), request_meta || {})
                                        .deliver_later(queue: 'critical')
    DeviceVerification::TokenService.new(user: user, jti: jti).generate_token
  rescue StandardError
    # The challenge could not be dispatched (e.g. queue outage). Release the stored
    # code and the issuance reservation so a transient failure does not burn the
    # user's 24h budget across retries, then re-raise so the failure surfaces.
    release_reservation(jti)
    raise
  end

  class << self
    def redeem(token:, code:)
      claims = DeviceVerification::TokenService.new(token: token).decode_claims
      return { error: :invalid_token } if claims.blank?

      user = User.find_by(id: claims[:user_id])
      return { error: :invalid_token } unless user
      return { error: :stale } if user.mfa_enabled? || !user.active_for_authentication?
      # Password auth via DTA is scoped to provider 'email'; redemption must not widen that
      return { error: :stale } unless user.provider == 'email'
      return { error: :stale } unless claims[:stamp] == DeviceVerification::TokenService.stamp_for(user)

      consume(user, claims[:jti], code.to_s)
    end

    def code_key(user, jti)
      format(::Redis::RedisKeys::DEVICE_VERIFICATION_CODE, user_id: user.id, jti: jti)
    end

    def digest_for(code, jti)
      OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, "#{jti}:#{code}")
    end

    private

    def consume(user, jti, code)
      # Increment BEFORE evaluating: a read-then-increment gate lets parallel
      # requests all observe a low count and blow past the cap. Counting the
      # attempt first bounds total evaluations regardless of concurrency.
      attempts_key = format(::Redis::RedisKeys::DEVICE_VERIFICATION_ATTEMPTS, user_id: user.id, jti: jti)
      attempts = ::Redis::Alfred.incr(attempts_key)
      ::Redis::Alfred.expire(attempts_key, CODE_TTL.to_i) if attempts == 1
      return { error: :locked } if attempts > MAX_ATTEMPTS

      # delete_if_equals makes validation and consumption one atomic op: two racing
      # correct submissions cannot both pass. Success is ONLY the executed MULTI
      # result [1]; a value mismatch returns "OK" from unwatch and must not pass.
      deleted = ::Redis::Alfred.delete_if_equals(code_key(user, jti), digest_for(code, jti))
      return { user: user } if deleted.is_a?(Array) && deleted.first.to_i == 1

      return { error: :expired } unless ::Redis::Alfred.exists?(code_key(user, jti))

      { error: :invalid_code }
    end
  end

  private

  def issuance_allowed?
    key = format(::Redis::RedisKeys::DEVICE_VERIFICATION_ISSUANCE, user_id: user.id)
    count = ::Redis::Alfred.incr(key)
    # Self-heal a counter left without expiry by a crash between INCR and EXPIRE,
    # otherwise the user's budget never resets.
    ::Redis::Alfred.expire(key, ISSUANCE_WINDOW.to_i) if count == 1 || ::Redis::Alfred.ttl(key).to_i.negative?
    count <= ISSUANCE_LIMIT
  end

  def release_reservation(jti)
    ::Redis::Alfred.delete(self.class.code_key(user, jti)) if jti.present?
    issuance_key = format(::Redis::RedisKeys::DEVICE_VERIFICATION_ISSUANCE, user_id: user.id)
    ::Redis::Alfred.with { |conn| conn.decr(issuance_key) }
  end
end
