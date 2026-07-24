module Imap::Authentication
  DEFAULT_MECHANISM = 'plain'.freeze
  USER_CONFIGURABLE_MECHANISMS = %w[plain login cram-md5].freeze

  module_function

  def normalize(mechanism)
    mechanism.presence || DEFAULT_MECHANISM
  end

  def validate_user_configurable!(mechanism)
    normalized_mechanism = normalize(mechanism).to_s.downcase
    return normalized_mechanism if USER_CONFIGURABLE_MECHANISMS.include?(normalized_mechanism)

    allowed_values = USER_CONFIGURABLE_MECHANISMS.join(', ')
    raise StandardError, "Invalid IMAP authentication mechanism. Allowed values: #{allowed_values}"
  end

  def authenticate!(imap, mechanism, username, password)
    normalized_mechanism = normalize(mechanism).to_s.downcase

    case normalized_mechanism
    when 'cram-md5'
      imap.authenticate('CRAM-MD5', username, password)
    when 'login'
      imap.login(username, password)
    else
      imap.authenticate(normalize(mechanism), username, password)
    end
  end
end
