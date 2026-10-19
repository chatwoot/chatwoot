# The one-time code a conversation is waiting on. A conversation holds one code at a time.
#
# The code is stored as a digest, together with the address it was sent to, in one key.
# Storing a new code replaces the code and its address in one write.
# A typed code is checked by building the same value again and comparing the two.
class Captain::EmailVerification::Code
  TTL = 30.minutes
  MAX_ATTEMPTS = 5

  pattr_initialize :conversation

  # A new code starts with a full set of attempts. Both writes run together, so an overlapping store cannot clear the attempts of a newer code.
  def store(email, code)
    ::Redis::Alfred.with do |conn|
      conn.multi do |transaction|
        transaction.setex(code_key, TTL.to_i, stored_value(email, code))
        transaction.del(attempts_key)
      end
    end
  end

  # Yields the address on a correct code, and returns :verified, :invalid_code, :locked or :expired
  def consume(typed_code)
    stored = ::Redis::Alfred.get(code_key)
    return :expired if stored.blank?
    # Count the attempt before checking it, so parallel guesses cannot all pass under the cap
    return :locked if attempts.exceeded?

    email = JSON.parse(stored)['email']
    # delete_if_equals checks and consumes the code in one step
    return :invalid_code unless ::Redis::Alfred.delete_if_equals(code_key, stored_value(email, typed_code.to_s.strip)) == [1]

    # The attempts are left to expire. Clearing them here could reset the count of a code stored a moment ago.
    yield email
    :verified
  end

  def attempts_left
    attempts.remaining
  end

  private

  def stored_value(email, code)
    { email: email, digest: OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, "#{conversation.id}:#{email}:#{code}") }.to_json
  end

  def attempts
    ::Redis::RateLimit.new(attempts_key, limit: MAX_ATTEMPTS, window: TTL)
  end

  def code_key
    format(::Redis::RedisKeys::CAPTAIN_EMAIL_VERIFICATION_CODE, conversation_id: conversation.id)
  end

  def attempts_key
    format(::Redis::RedisKeys::CAPTAIN_EMAIL_VERIFICATION_ATTEMPTS, conversation_id: conversation.id)
  end
end
