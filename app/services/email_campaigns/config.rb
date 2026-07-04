module EmailCampaigns
  class Config
    BOOLEAN = ActiveModel::Type::Boolean.new

    DEFAULT_REGION = 'sa-east-1'.freeze
    CONFIGURATION_SET_NAME = 'autonomia-email-campaigns'.freeze

    def self.enabled?
      ::Crm::Config.enabled? && BOOLEAN.cast(ENV.fetch('EMAIL_CAMPAIGN_ENABLED', false))
    end

    def self.region
      ENV.fetch('EMAIL_CAMPAIGN_AWS_REGION', nil).presence ||
        ENV.fetch('AWS_REGION', nil).presence ||
        DEFAULT_REGION
    end

    def self.access_key_id
      ENV.fetch('EMAIL_CAMPAIGN_AWS_ACCESS_KEY_ID', nil).presence ||
        ENV.fetch('AWS_ACCESS_KEY_ID', '')
    end

    def self.secret_access_key
      ENV.fetch('EMAIL_CAMPAIGN_AWS_SECRET_ACCESS_KEY', nil).presence ||
        ENV.fetch('AWS_SECRET_ACCESS_KEY', '')
    end

    # SES auth: use explicit static keys only when BOTH are set (EMAIL_CAMPAIGN_AWS_* or
    # AWS_*). Otherwise return nil so the client falls back to the default AWS credential
    # chain — on EC2 that resolves the instance-role creds via IMDS, so no static secret
    # needs to live in the environment.
    def self.static_credentials
      return nil unless access_key_id.present? && secret_access_key.present?

      Aws::Credentials.new(access_key_id, secret_access_key)
    end

    def self.configuration_set_name
      ENV.fetch('EMAIL_CAMPAIGN_SES_CONFIGURATION_SET', CONFIGURATION_SET_NAME)
    end
  end
end
