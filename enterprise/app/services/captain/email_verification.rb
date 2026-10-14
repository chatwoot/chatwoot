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
  # Tools place the verified address in URLs and JSON bodies, so it can only hold characters that cannot change the request
  EMAIL_PATTERN = /\A[a-z0-9._+-]+@[a-z0-9.-]+\z/

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
    return :invalid_email unless EMAIL_PATTERN.match?(email) && URI::MailTo::EMAIL_REGEXP.match?(email)
    return :already_verified if verified_email == email
    return :unavailable unless Captain::EmailVerificationMailer.deliverable?
    return :rate_limited unless send_allowed?(email)

    code = format("%0#{CODE_LENGTH}d", SecureRandom.random_number(10**CODE_LENGTH))
    store_code(email, code)
    inbox = contact_inbox.inbox
    Captain::EmailVerificationMailer.with(account: inbox.account).verification_code(inbox, email, self.class.encrypt_code(code)).deliver_later
    :sent
  end

  def verify(code)
    stored = ::Redis::Alfred.get(key(:CODE))
    return :expired if stored.blank?

    email = stored.rpartition(':').first

    # Count the attempt before checking it, so parallel guesses cannot all pass under the cap
    return :locked if attempts_limit.exceeded?

    # delete_if_equals checks and consumes the code in one step
    return :invalid_code unless ::Redis::Alfred.delete_if_equals(key(:CODE), code_value(email, code.to_s.strip)) == [1]

    # The attempts are left to expire. Clearing them here could reset the count of a code sent a moment ago.
    ::Redis::Alfred.setex(key(:VERIFIED), email, VERIFIED_TTL)
    :verified
  end

  def verified_email
    ::Redis::Alfred.get(key(:VERIFIED)).presence
  end

  def attempts_left
    attempts_limit.remaining
  end

  private

  # A new code replaces the previous one and its address in one write, and starts with a full set of attempts
  def store_code(email, code)
    ::Redis::Alfred.setex(key(:CODE), code_value(email, code), CODE_TTL)
    ::Redis::Alfred.delete(key(:ATTEMPTS))
  end

  # The address is stored next to the digest of its code. The address pattern does not allow a colon, so the last one separates them.
  def code_value(email, code)
    "#{email}:#{OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, "#{contact_inbox.id}:#{email}:#{code}")}"
  end

  # Both budgets are counted on every request, so a blocked session still cannot be used to flood one address
  def send_allowed?(email)
    email_key = format(::Redis::RedisKeys::CAPTAIN_EMAIL_VERIFICATION_EMAIL_SENDS, email_digest: Digest::SHA256.hexdigest(email))
    [key(:SENDS), email_key].map { |send_key| ::Redis::RateLimit.new(send_key, limit: SEND_LIMIT, window: SEND_WINDOW).exceeded? }.none?
  end

  def attempts_limit
    ::Redis::RateLimit.new(key(:ATTEMPTS), limit: MAX_ATTEMPTS, window: CODE_TTL)
  end

  def key(name)
    format(::Redis::RedisKeys.const_get("CAPTAIN_EMAIL_VERIFICATION_#{name}"), contact_inbox_id: contact_inbox.id)
  end
end
