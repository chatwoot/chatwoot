# frozen_string_literal: true

# Backward compatible delegators from Net::IMAP to Net::IMAP::SASL.
module Net::IMAP::Authenticators

  # Deprecated.  Use Net::IMAP::SASL.add_authenticator instead.
  def add_authenticator(...)
    warn(
      "%s.%s is deprecated.  Use %s.%s instead." % [
        Net::IMAP, __method__, Net::IMAP::SASL, __method__
      ],
      uplevel: 1
    )
    Net::IMAP::SASL.add_authenticator(...)
  end

  # Deprecated.  Use Net::IMAP::SASL.authenticator instead.
  def authenticator(...)
    warn(
      "%s.%s is deprecated.  Use %s.%s instead." % [
        Net::IMAP, __method__, Net::IMAP::SASL, __method__
      ],
      uplevel: 1
    )
    Net::IMAP::SASL.authenticator(...)
  end

  Net::IMAP.extend self
end

class Net::IMAP
  PlainAuthenticator = SASL::PlainAuthenticator # :nodoc:
  deprecate_constant :PlainAuthenticator

  XOauth2Authenticator = SASL::XOAuth2Authenticator # :nodoc:
  deprecate_constant :XOauth2Authenticator
end
