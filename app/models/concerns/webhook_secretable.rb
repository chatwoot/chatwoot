module WebhookSecretable
  extend ActiveSupport::Concern

  included do
    has_secure_token :secret
    encrypts :secret if Chatwoot.encryption_configured?
  end

  def reset_secret!
    regenerate_secret
    reload
  end
end
