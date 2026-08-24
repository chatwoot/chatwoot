# [whisker] Generates, delivers and verifies email one-time-passcodes (OTP).
# Used for passwordless login and email verification, gated per account.
module Whisker
  class EmailOtpService
    OTP_TTL = 300 # seconds
    OTP_LENGTH = 6

    def initialize(email:, account: nil)
      @email = email.to_s.downcase
      @account = account
    end

    def send
      return false unless account.nil? || account.otp_via_email_enabled?

      code = generate
      Redis::Alfred.set(redis_key, code, ex: OTP_TTL)
      Whisker::Mailer.with_smtp(account) { OtpMailer.with(account: account).send_code(@email, code).deliver_now }
      true
    rescue StandardError => e
      ChatwootExceptionTracker.new(e).capture_exception if defined?(ChatwootExceptionTracker)
      false
    end

    def verify(code)
      stored = Redis::Alfred.get(redis_key)
      return false if stored.blank?

      if stored.to_s == code.to_s
        Redis::Alfred.delete(redis_key)
        true
      else
        false
      end
    end

    private

    def generate
      OTP_LENGTH.times.map { rand(0..9) }.join
    end

    def redis_key
      "whisker:otp:#{@email}"
    end
  end
end
