# All connections to external Chatwoot servers have been disabled.
# This instance operates fully independently.
class ChatwootHub
  BASE_URL = ''.freeze
  PING_URL = ''.freeze
  REGISTRATION_URL = ''.freeze
  PUSH_NOTIFICATION_URL = ''.freeze
  EVENTS_URL = ''.freeze
  BILLING_URL = ''.freeze
  CAPTAIN_ACCOUNTS_URL = ''.freeze

  def self.installation_identifier
    identifier = InstallationConfig.find_by(name: 'INSTALLATION_IDENTIFIER')&.value
    identifier ||= InstallationConfig.create!(name: 'INSTALLATION_IDENTIFIER', value: SecureRandom.uuid).value
    identifier
  end

  def self.billing_url
    ''
  end

  def self.pricing_plan
    'enterprise'
  end

  def self.pricing_plan_quantity
    100_000
  end

  def self.support_config
    {
      support_website_token: nil,
      support_script_url: nil,
      support_identifier_hash: nil
    }
  end

  def self.instance_config
    {
      installation_identifier: installation_identifier,
      installation_version: Chatwoot.config[:version],
      installation_host: URI.parse(ENV.fetch('FRONTEND_URL', '')).host,
      installation_env: ENV.fetch('INSTALLATION_ENV', ''),
      edition: 'enterprise'
    }
  end

  def self.instance_metrics
    {}
  end

  def self.fetch_count(_model)
    0
  end

  # Disabled - no external connections
  def self.sync_with_hub
    nil
  end

  # Disabled - no external connections
  def self.register_instance(_company_name, _owner_name, _owner_email)
    nil
  end

  # Disabled - no external connections
  def self.send_push(_fcm_options)
    nil
  end

  # Disabled - no external connections
  def self.get_captain_settings(_account)
    nil
  end

  # Disabled - no external connections
  def self.emit_event(_event_name, _event_data)
    nil
  end
end
