class ChatwootHub
  BASE_URL = ENV.fetch('CHATWOOT_HUB_URL', 'https://hub.2.chatwoot.com')
  PING_URL = "#{BASE_URL}/ping".freeze
  REGISTRATION_URL = "#{BASE_URL}/instances".freeze
  PUSH_NOTIFICATION_URL = "#{BASE_URL}/send_push".freeze
  EVENTS_URL = "#{BASE_URL}/events".freeze
  BILLING_URL = "#{BASE_URL}/billing".freeze

  def self.installation_identifier
    identifier = InstallationConfig.find_by(name: 'INSTALLATION_IDENTIFIER')&.value
    identifier ||= InstallationConfig.create!(name: 'INSTALLATION_IDENTIFIER', value: SecureRandom.uuid).value
    identifier
  end

  def self.billing_url
    "#{BILLING_URL}?installation_identifier=#{installation_identifier}"
  end

  def self.pricing_plan
    InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'community'
  end

  def self.pricing_plan_quantity
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
      accounts_count: Account.count,
      users_count: User.count,
      inboxes_count: Inbox.count,
      conversations_count: Conversation.count,
      incoming_messages_count: Message.incoming.count,
      outgoing_messages_count: Message.outgoing.count,
      additional_information: {}
    }
  end

  def self.sync_with_hub
    begin
      info = instance_config
      info = info.merge(instance_metrics) unless ENV['DISABLE_TELEMETRY']
      response = RestClient.post(PING_URL, info.to_json, { content_type: :json, accept: :json })
      parsed_response = JSON.parse(response)
    rescue *ExceptionList::REST_CLIENT_EXCEPTIONS => e
      Rails.logger.error "Exception: #{e.message}"
    rescue StandardError => e
      ChatwootExceptionTracker.new(e).capture_exception
    end
    parsed_response
  end

  def self.register_instance(company_name, owner_name, owner_email)
    info = { company_name: company_name, owner_name: owner_name, owner_email: owner_email, subscribed_to_mailers: true }
    RestClient.post(REGISTRATION_URL, info.merge(instance_config).to_json, { content_type: :json, accept: :json })
  rescue *ExceptionList::REST_CLIENT_EXCEPTIONS => e
    Rails.logger.error "Exception: #{e.message}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
  end

  def self.send_browser_push(fcm_token_list, fcm_options)
    info = { fcm_token_list: fcm_token_list, fcm_options: fcm_options }
    RestClient.post(PUSH_NOTIFICATION_URL, info.merge(instance_config).to_json, { content_type: :json, accept: :json })
  rescue *ExceptionList::REST_CLIENT_EXCEPTIONS => e
    Rails.logger.error "Exception: #{e.message}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
  end

  def self.emit_event(event_name, event_data)
    return if ENV['DISABLE_TELEMETRY']

    info = { event_name: event_name, event_data: event_data }
    RestClient.post(EVENTS_URL, info.merge(instance_config).to_json, { content_type: :json, accept: :json })
  rescue *ExceptionList::REST_CLIENT_EXCEPTIONS => e
    Rails.logger.error "Exception: #{e.message}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
  end
end
