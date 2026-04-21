# TODO: lets use HTTParty instead of RestClient
class ChatwootHub
  DEFAULT_BASE_URL = 'https://hub.2.chatwoot.com'.freeze

  def self.base_url
    DEFAULT_BASE_URL
  end

  def self.ping_url
    "#{base_url}/ping"
  end

  def self.registration_url
    "#{base_url}/instances"
  end

  def self.push_notification_url
    "#{base_url}/send_push"
  end

  def self.events_url
    "#{base_url}/events"
  end

  def self.billing_base_url
    "#{base_url}/billing"
  end

  def self.installation_identifier
    identifier = InstallationConfig.find_by(name: 'INSTALLATION_IDENTIFIER')&.value
    identifier ||= InstallationConfig.create!(name: 'INSTALLATION_IDENTIFIER', value: SecureRandom.uuid).value
    identifier
  end

  def self.billing_url
    "#{billing_base_url}?installation_identifier=#{installation_identifier}"
  end

  def self.pricing_plan
    return 'community' unless ChatwootApp.enterprise?

    InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value || 'community'
  end

  def self.pricing_plan_quantity
    return 0 unless ChatwootApp.enterprise?

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
    begin
      info = instance_config
      info = info.merge(instance_metrics) unless ENV['DISABLE_TELEMETRY']
      response = RestClient.post(ping_url, info.to_json, { content_type: :json, accept: :json })
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
    RestClient.post(registration_url, info.merge(instance_config).to_json, { content_type: :json, accept: :json })
  rescue *ExceptionList::REST_CLIENT_EXCEPTIONS => e
    Rails.logger.error "Exception: #{e.message}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
  end

  def self.send_push(fcm_options)
    info = { fcm_options: fcm_options }
    RestClient.post(push_notification_url, info.merge(instance_config).to_json, { content_type: :json, accept: :json })
  rescue *ExceptionList::REST_CLIENT_EXCEPTIONS => e
    Rails.logger.error "Exception: #{e.message}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
  end

  def self.emit_event(event_name, event_data)
    return if ENV['DISABLE_TELEMETRY']

    info = { event_name: event_name, event_data: event_data }
    RestClient.post(events_url, info.merge(instance_config).to_json, { content_type: :json, accept: :json })
  rescue *ExceptionList::REST_CLIENT_EXCEPTIONS => e
    Rails.logger.error "Exception: #{e.message}"
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
  end
end

ChatwootHub.singleton_class.prepend_mod_with('ChatwootHub')
