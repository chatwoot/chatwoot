require 'httparty'
require_relative 'default_configs'

class AiBackendService::ConfigurationService
  include HTTParty
  include AiBackendService::DefaultConfigs

  class ConfigurationError < StandardError; end

  CONFIGURATION_KEYS = {
    NOTIFICATIONS: 'notifications_config',
    MESSAGES: 'messaging_config',
    GENERAL_STORE: 'general_store_config',
    ECOMMERCE: 'ecommerce_config',
    CALENDLY: 'calendly_config',
    CONVERSATION: 'conversation_config'
  }.freeze

  def initialize
    self.class.base_uri ai_backend_api_url
    self.class.headers({
                         'Content-Type' => 'application/json',
                         'Authorization' => 'application/json'
                       })
  end

  def create_default_store_configs(store_id)
    CONFIGURATION_KEYS.each_value do |config_key|
      create_configuration(store_id, config_key, default_configs[config_key])
    end
  rescue StandardError => e
    Rails.logger.error "Configuration creation failed: #{e.message}"
    raise ConfigurationError, "Configuration creation failed: #{e.message}"
  end

  def create_configuration(store_id, config_key, config_data)
    existing_config_data = get_configuration(store_id, config_key)
    data_to_save = existing_config_data.merge(config_data)

    configuration_payload = {
      key: config_key,
      store_id: store_id,
      data: data_to_save
    }

    response = self.class.put(
      "#{ai_backend_api_url}/api/configurations/",
      body: { configuration: configuration_payload }.to_json,
      headers: self.class.headers
    )

    handle_response(response)

    response.parsed_response
  end

  def get_configuration(store_id, config_key)
    response = self.class.get(
      "#{ai_backend_api_url}/api/configurations/",
      query: { key: config_key, store_id: store_id },
      headers: self.class.headers
    )

    handle_response(response)

    response.parsed_response['configuration']['data']
  end

  private

  def handle_response(response)
    raise ConfigurationError, "Bad Request, url: #{response.request.last_uri}" if response.code == 404
    raise ConfigurationError, "Error creating configuration: #{response.code} - #{response.body}" if response.code == 400
    raise ConfigurationError, "Unexpected error: #{response.code} - #{response.body}" unless response.success?
  end

  def ai_backend_api_url
    Rails.application.config.ai_backend_api_url ||
      ENV['AI_BACKEND_URL'] ||
      Rails.application.credentials.ai_backend_api_url
  end
end


