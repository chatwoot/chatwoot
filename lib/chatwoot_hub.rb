# TODO: lets use HTTParty instead of RestClient
class ChatwootHub
  BASE_URL = ENV.fetch('CHATWOOT_HUB_URL', 'https://hub.2.chatwoot.com')
  PING_URL = "#{BASE_URL}/ping".freeze
  REGISTRATION_URL = "#{BASE_URL}/instances".freeze
  PUSH_NOTIFICATION_URL = "#{BASE_URL}/send_push".freeze
  EVENTS_URL = "#{BASE_URL}/events".freeze
  BILLING_URL = "#{BASE_URL}/billing".freeze
  CAPTAIN_ACCOUNTS_URL = "#{BASE_URL}/instance_captain_accounts".freeze

  def self.installation_identifier
    identifier = InstallationConfig.find_by(name: 'INSTALLATION_IDENTIFIER')&.value
    identifier ||= InstallationConfig.create!(name: 'INSTALLATION_IDENTIFIER', value: SecureRandom.uuid).value
    identifier
  end

  def self.billing_url
    "#{BILLING_URL}?installation_identifier=#{installation_identifier}"
  end

  def self.pricing_plan
    return 'enterprise' if ChatwootApp.enterprise?

    InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'community'
  end

  def self.pricing_plan_quantity
    return 999999 if ChatwootApp.enterprise?

    InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')&.value || 0
  end

  def self.support_config
    {
      support_website_token: InstallationConfig.find_by(name: 'CHATWOOT_SUPPORT_WEBSITE_TOKEN')&.value,
      support_script_url: InstallationConfig.find_by(name: 'CHATWOOT_SUPPORT_SCRIPT_URL')&.value,
      support_identifier_hash: InstallationConfig.find_by(name: 'CHATWOOT_SUPPORT_IDENTIFIER_HASH')&.value
    }
  end

  def self.instance_config
    {
      installation_identifier: installation_identifier,
      installation_version: Chatwoot.config[:version],
      installation_host: URI.parse(ENV.fetch('FRONTEND_URL', '')).host,
      installation_env: ENV.fetch('INSTALLATION_ENV', ''),
      edition: ENV.fetch('CW_EDITION', '')
    }
  end

  def self.instance_metrics
    {
      accounts_count: fetch_count(Account),
      users_count: fetch_count(User),
      inboxes_count: fetch_count(Inbox),
      conversations_count: fetch_count(Conversation),
      incoming_messages_count: fetch_count(Message.incoming),
      outgoing_messages_count: fetch_count(Message.outgoing),
      additional_information: {}
    }
  end

  def self.fetch_count(model)
    model.last&.id || 0
  end

  def self.sync_with_hub
    # Telemetry disabled - no data sent
    return {}
  end

  def self.register_instance(company_name, owner_name, owner_email)
    # Telemetry disabled - no registration data sent
    return true
  end

  def self.send_push(fcm_options)
    # Telemetry disabled - no push notifications sent via hub
    return
  end

  def self.get_captain_settings(account)
    info = {
      installation_identifier: installation_identifier,
      chatwoot_account_id: account.id,
      account_name: account.name
    }
    HTTParty.post(CAPTAIN_ACCOUNTS_URL,
                  body: info.to_json,
                  headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' })
  end

  def self.emit_event(event_name, event_data)
    # Telemetry disabled - no events sent
    return
  end
end
