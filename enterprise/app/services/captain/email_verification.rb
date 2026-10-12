# Verifies that the customer in a conversation can read an email address, by
# emailing a one-time code that they type back into the conversation.
#
# Verification is bound to the contact inbox and to the exact address that
# received the code. It expires on its own, so a new session or a different
# address is never treated as verified.
class Captain::EmailVerification
  CODE_LENGTH = 6
  CODE_TTL = 30.minutes
  MAX_ATTEMPTS = 5
  SEND_LIMIT = 5
  SEND_WINDOW = 1.hour
  VERIFIED_TTL = 24.hours

  pattr_initialize :contact_inbox

  # The code must never appear in serialized job arguments, since Sidekiq logs the payload when a job fails
  def self.encrypt_code(code)
    code_encryptor.encrypt_and_sign(code)
  end

  def self.decrypt_code(ciphertext)
    code_encryptor.decrypt_and_verify(ciphertext)
  end

  def self.code_encryptor
    key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base).generate_key('captain_email_verification_code', 32)
    ActiveSupport::MessageEncryptor.new(key)
  end
  private_class_method :code_encryptor

  def send_code(email)
    email = email.to_s.strip.downcase
    return :invalid_email unless Devise.email_regexp.match?(email)
    return :already_verified if verified_email == email
    return :rate_limited unless send_allowed?(email)

    code = format("%0#{CODE_LENGTH}d", SecureRandom.random_number(10**CODE_LENGTH))
    store_code(email, code)
    inbox = contact_inbox.inbox
    Captain::EmailVerificationMailer.with(account: inbox.account).verification_code(inbox, email, self.class.encrypt_code(code)).deliver_later
    :sent
  end

  def verify(code)
    email = ::Redis::Alfred.get(key(:PENDING))
    return :expired if email.blank?

    # Count the attempt before checking it, so parallel guesses cannot all pass under the cap
    return :locked if increment(key(:ATTEMPTS), CODE_TTL) > MAX_ATTEMPTS

    # delete_if_equals checks and consumes the code in one step. Only an executed MULTI, which returns [1], is a match.
    deleted = ::Redis::Alfred.delete_if_equals(key(:CODE), digest(email, code.to_s.strip))
    return :invalid_code unless deleted.is_a?(Array) && deleted.first.to_i == 1

    ::Redis::Alfred.setex(key(:VERIFIED), email, VERIFIED_TTL)
    ::Redis::Alfred.delete(key(:PENDING))
    ::Redis::Alfred.delete(key(:ATTEMPTS))
    :verified
  end

  def verified_email
    ::Redis::Alfred.get(key(:VERIFIED)).presence
  end

  def pending_email
    ::Redis::Alfred.get(key(:PENDING)).presence
  end

  def attempts_left
    [MAX_ATTEMPTS - ::Redis::Alfred.get(key(:ATTEMPTS)).to_i, 0].max
  end

  private

  # A new code replaces the previous one and starts with a full set of attempts
  def store_code(email, code)
    ::Redis::Alfred.setex(key(:CODE), digest(email, code), CODE_TTL)
    ::Redis::Alfred.setex(key(:PENDING), email, CODE_TTL)
    ::Redis::Alfred.delete(key(:ATTEMPTS))
  end

  # Both budgets are counted on every request, so a blocked session still cannot be used to flood one address
  def send_allowed?(email)
    email_key = format(::Redis::RedisKeys::CAPTAIN_EMAIL_VERIFICATION_EMAIL_SENDS, email_digest: Digest::SHA256.hexdigest(email))
    [increment(key(:SENDS), SEND_WINDOW), increment(email_key, SEND_WINDOW)].max <= SEND_LIMIT
  end

  def increment(redis_key, window)
    count = ::Redis::Alfred.incr(redis_key)
    # Also repairs a counter left without an expiry by a crash between INCR and EXPIRE
    ::Redis::Alfred.expire(redis_key, window.to_i) if count == 1 || ::Redis::Alfred.ttl(redis_key).to_i.negative?
    count
  end

  def digest(email, code)
    OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, "#{contact_inbox.id}:#{email}:#{code}")
  end

  def key(name)
    format(::Redis::RedisKeys.const_get("CAPTAIN_EMAIL_VERIFICATION_#{name}"), contact_inbox_id: contact_inbox.id)
  end
end
