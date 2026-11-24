# The shared secret Vapi sends back on every webhook, set on the server config of each Vapi call
module Voice::Captain::WebhookAuth
  HEADER = 'X-Chatwoot-Vapi-Secret'.freeze

  def self.valid?(value)
    secret = Voice::Captain::VapiConfig.webhook_secret
    secret.present? && ActiveSupport::SecurityUtils.secure_compare(value.to_s, secret)
  end
end
