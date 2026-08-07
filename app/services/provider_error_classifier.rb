require 'net/smtp'

# Classifies an outbound provider error (SMTP / OAuth / HTTP) into a coarse
# category so callers can decide how to react. This ticket only ships the
# classification; retry behaviour is wired up separately (CW-7882).
#
#   ProviderErrorClassifier.classify(error) => Symbol
#     :throttle   retryable rate-limit / slow-down
#     :transient  network blip worth a limited retry
#     :auth       credentials / permission problem
#     :permanent  do not retry
#     :unknown    unmatched, caller decides (default fail-fast)
class ProviderErrorClassifier
  TRANSIENT_ERRORS = [
    Net::OpenTimeout, Net::ReadTimeout, Timeout::Error,
    Errno::ECONNRESET, Errno::ECONNREFUSED, SocketError, IOError,
    OpenSSL::SSL::SSLError
  ].freeze

  PERMANENT_ERRORS = [Net::SMTPFatalError, Net::SMTPSyntaxError].freeze

  THROTTLE_PATTERNS = /too many login attempts|too many messages|rate.?limit|throttl|try again later|slow down|too many requests|\b429\b/i
  # `x` flag is only for line-wrapping, so every literal space is written as `\s`.
  AUTH_PATTERNS = /invalid_grant|invalid_client|smtpclientauthentication\sis\sdisabled|revoked|
                   authentication\s(failed|required|unsuccessful)|username\sand\spassword\snot\saccepted|\b535\b/xi
  PERMANENT_PATTERNS = /recipient\s(address\s)?rejected|mailbox\s(unavailable|not\sfound)|user\sunknown|
                        no\ssuch\suser|address\srejected|message\srejected|content\s.*reject|policy/xi

  def self.classify(error)
    return :unknown if error.nil?

    message = error_message(error)
    code = smtp_reply_code(error, message)

    # Gmail sends "454 4.7.0 Too many login attempts" as an auth error class,
    # but a 4xx code means slow down, not bad credentials.
    return smtp_auth_code_class(code) if error.is_a?(Net::SMTPAuthenticationError)
    return :throttle if throttle?(error, message, code)
    return :auth if AUTH_PATTERNS.match?(message)
    return :transient if match_class?(error, TRANSIENT_ERRORS)
    return :permanent if permanent?(error, message, code)

    :unknown
  end

  def self.smtp_auth_code_class(code)
    code&.start_with?('4') ? :throttle : :auth
  end

  def self.throttle?(error, message, code)
    error.is_a?(Net::SMTPServerBusy) || code&.start_with?('4') || THROTTLE_PATTERNS.match?(message)
  end

  def self.permanent?(error, message, code)
    match_class?(error, PERMANENT_ERRORS) || code&.start_with?('5') || PERMANENT_PATTERNS.match?(message)
  end

  def self.match_class?(error, classes)
    classes.any? { |klass| error.is_a?(klass) }
  end

  def self.error_message(error)
    (error.respond_to?(:message) ? error.message : error).to_s
  rescue StandardError
    ''
  end

  # Only SMTP replies carry a 4xx/5xx reply code with retry semantics; a bare
  # "400"/"500" in an HTTP/OAuth message must not be read as an SMTP code.
  # Returns the 3-digit code (leading, else the first 4xx/5xx token) or nil.
  def self.smtp_reply_code(error, message)
    return nil unless error.is_a?(Net::SMTPError)

    message[/\A\s*(\d{3})\b/, 1] || message[/\b([45]\d\d)\b/, 1]
  end

  private_class_method :smtp_auth_code_class, :throttle?, :permanent?, :match_class?, :error_message, :smtp_reply_code
end
