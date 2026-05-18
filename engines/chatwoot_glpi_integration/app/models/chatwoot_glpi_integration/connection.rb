module ChatwootGlpiIntegration
  # One row per Chatwoot account. Stores GLPI 11 OAuth2 client credentials.
  #
  # Token rotation: short-lived access tokens are cached in Rails.cache under
  # "glpi:token:<account_id>" with the configured TTL — never persisted here.
  class Connection < ApplicationRecord
    self.table_name = 'chatwoot_glpi_connections'

    encrypts :client_secret

    belongs_to :account, class_name: '::Account'

    validates :base_url,   presence: true, format: { with: %r{\Ahttps?://}, message: 'must include scheme' }
    validates :client_id,  presence: true
    validates :client_secret, presence: true

    def api_url
      "#{base_url.chomp('/')}#{api_path}"
    end

    def token_endpoint
      "#{base_url.chomp('/')}/api.php/token"  # GLPI 11 OAuth2 token endpoint
    end

    # Per-account secret used to verify inbound webhooks.
    # Falls back to ENV if not set on the row.
    def effective_webhook_secret
      webhook_secret.presence || ENV.fetch(ChatwootGlpiIntegration.configuration.webhook_secret_env, nil)
    end
  end
end
