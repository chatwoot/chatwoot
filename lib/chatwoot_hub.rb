# FassZap Hub - Modified for minimal data sharing
# Only maintains push notification functionality
class ChatwootHub
  BASE_URL = ENV.fetch('CHATWOOT_HUB_URL', 'https://hub.2.chatwoot.com')
  PUSH_NOTIFICATION_URL = "#{BASE_URL}/send_push".freeze

  # Disabled URLs - no longer used in FassZap
  # PING_URL = "#{BASE_URL}/ping".freeze
  # REGISTRATION_URL = "#{BASE_URL}/instances".freeze
  # EVENTS_URL = "#{BASE_URL}/events".freeze
  # BILLING_URL = "#{BASE_URL}/billing".freeze
  # CAPTAIN_ACCOUNTS_URL = "#{BASE_URL}/instance_captain_accounts".freeze

  def self.installation_identifier
    identifier = InstallationConfig.find_by(name: 'INSTALLATION_IDENTIFIER')&.value
    identifier ||= InstallationConfig.create!(name: 'INSTALLATION_IDENTIFIER', value: SecureRandom.uuid).value
    identifier
  end

  # FassZap: Always return enterprise plan
  def self.pricing_plan
    'enterprise'
  end

  def self.pricing_plan_quantity
    10 # Default quantity for FassZap enterprise
  end

  # FassZap: Minimal support config - no external support integration
  def self.support_config
    {
      support_website_token: nil,
      support_script_url: nil,
      support_identifier_hash: nil
    }
  end

  # FassZap: Minimal instance config for push notifications only
  def self.instance_config
    {
      installation_identifier: installation_identifier,
      installation_version: Chatwoot.config[:version],
      edition: 'enterprise' # Always enterprise for FassZap
    }
  end

  # FassZap: Disabled - no sync with external hub
  def self.sync_with_hub
    Rails.logger.info "FassZap: Hub sync disabled - running in standalone mode"
    nil
  end

  # FassZap: Disabled - no instance registration
  def self.register_instance(company_name, owner_name, owner_email)
    Rails.logger.info "FassZap: Instance registration disabled - running in standalone mode"
    nil
  end

  # FassZap: Keep push notifications - essential for mobile notifications
  def self.send_push(fcm_options)
    info = { fcm_options: fcm_options }
    RestClient.post(PUSH_NOTIFICATION_URL, info.merge(instance_config).to_json, { content_type: :json, accept: :json })
  rescue *ExceptionList::REST_CLIENT_EXCEPTIONS => e
    Rails.logger.error "FassZap Push Notification Exception: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "FassZap Push Notification Error: #{e.message}"
  end

  # FassZap: Disabled - no captain integration needed
  def self.get_captain_settings(account)
    Rails.logger.info "FassZap: Captain integration disabled"
    nil
  end

  # FassZap: Disabled - no event tracking
  def self.emit_event(event_name, event_data)
    Rails.logger.debug "FassZap: Event tracking disabled - #{event_name}"
    nil
  end
end
