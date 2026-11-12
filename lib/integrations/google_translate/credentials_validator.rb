# KEY_ERRORS names Google's error classes when this file loads, which can happen before ProcessorService requires the gem.
require 'google/cloud/translate/v3'

module Integrations::GoogleTranslate::CredentialsValidator
  KEY_FIELDS = %w[client_email private_key].freeze
  # Errors Google's client raises for a broken or rejected key. Its auth library raises a bare RuntimeError
  # for a key without KEY_FIELDS, which hooks saved before this check can still have.
  KEY_ERRORS = [Google::Cloud::Error, Signet::AuthorizationError, OpenSSL::PKey::PKeyError, RuntimeError].freeze

  def self.valid?(hook)
    credentials = hook.settings['credentials']
    return false unless credentials.is_a?(Hash) && KEY_FIELDS.all? { |field| credentials[field].present? }

    Integrations::GoogleTranslate::ProcessorService.new(hook: hook).detect('Hello')
    true
  rescue *KEY_ERRORS => e
    Rails.logger.warn("[google-translate-validator] #{e.class}: #{e.message}")
    false
  end
end
