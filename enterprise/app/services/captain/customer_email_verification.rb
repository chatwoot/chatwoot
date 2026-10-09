class Captain::CustomerEmailVerification
  CODE_TTL = 10.minutes
  SESSION_TTL = 15.minutes
  MAX_ATTEMPTS = 5
  ISSUANCE_LIMIT = 5
  RATE_LIMIT_SCRIPT = <<~LUA.freeze
    local count = redis.call('INCR', KEYS[1])
    if count == 1 then redis.call('EXPIRE', KEYS[1], ARGV[1]) end
    return count
  LUA

  def initialize(assistant:, conversation:)
    @assistant = assistant
    @conversation = conversation
  end

  def issue(email: nil)
    @email = (email.presence || @conversation.contact.email).to_s.strip.downcase
    return 'Ask the customer for a valid email address.' unless @email.match?(URI::MailTo::EMAIL_REGEXP)
    return 'Please wait before requesting another verification code.' unless issuance_allowed?

    code = format('%06d', SecureRandom.random_number(10**6))
    payload = { digest: digest(code), email: @email, contact_email: @conversation.contact.email, attempts: 0, verified: false }.to_json
    Redis::Alfred.setex(key, payload, CODE_TTL.to_i)
    Captain::CustomerVerificationMailer.with(account: @assistant.account)
                                       .verification_code(@email, encryptor.encrypt_and_sign(code)).deliver_later
    'Verification email queued. Ask the customer to enter the six-digit code from their email. Do not guess codes.'
  end

  def verify(code)
    return 'Enter the six-digit code from the verification email.' unless code.is_a?(String) && code.match?(/\A\d{6}\z/)

    return 'Email verified. Protected tools may now access this customer for 15 minutes.' if consume(code)

    'Invalid, expired, or exhausted verification code. No private data was accessed.'
  end

  def verified?
    verified_email.present?
  end

  def verified_email
    stored = Redis::Alfred.get(key)
    return if stored.blank?

    challenge = JSON.parse(stored)
    return unless challenge['verified'] == true && challenge['contact_email'] == @conversation.contact.email

    challenge.fetch('email')
  end

  def self.encryptor
    secret = Rails.application.key_generator.generate_key('captain_customer_email_verification', 32)
    ActiveSupport::MessageEncryptor.new(secret)
  end

  private

  delegate :encryptor, to: :class

  def consume(code)
    result = Redis::Alfred.with do |redis|
      redis.watch(key) do
        stored = redis.get(key)
        next redis.unwatch if stored.blank?

        challenge = JSON.parse(stored)
        next redis.unwatch if challenge['verified'] || challenge.fetch('attempts') >= MAX_ATTEMPTS

        update_challenge(redis, challenge, code)
      end
    end
    result == true
  end

  def update_challenge(redis, challenge, code)
    matched = ActiveSupport::SecurityUtils.secure_compare(challenge.fetch('digest'), digest(code))
    challenge['attempts'] += 1
    challenge['verified'] = matched
    ttl = matched ? SESSION_TTL.to_i : redis.ttl(key)
    return redis.unwatch unless ttl.positive?

    result = redis.multi { |transaction| transaction.setex(key, ttl, challenge.to_json) }
    matched && result.present?
  end

  def key
    "captain:customer:verification:#{@assistant.id}:#{@conversation.id}:#{@conversation.contact_id}"
  end

  def digest(value)
    OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, "#{@assistant.id}:#{@conversation.id}:#{value}")
  end

  def issuance_allowed?
    email_digest = OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, @email)
    rate_key = "captain:customer:issuance:#{@assistant.account_id}:#{email_digest}"
    conversation_rate_key = "#{key}:issuance"
    Redis::Alfred.with do |redis|
      [conversation_rate_key, rate_key].all? do |limit_key|
        redis.eval(RATE_LIMIT_SCRIPT, keys: [limit_key], argv: [1.hour.to_i]) <= ISSUANCE_LIMIT
      end
    end
  end
end
