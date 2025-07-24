require 'httparty'
require_relative 'default_configs'

class ChatscommerceService::ConfigurationService
  include HTTParty
  include ChatscommerceService::DefaultConfigs

  class ConfigurationError < StandardError; end

  CONFIGURATION_KEYS = {
    NOTIFICATIONS: 'notification_config',
    MESSAGES: 'messaging_config',
    GENERAL_STORE: 'general_store_config',
    ECOMMERCE: 'ecommerce_config',
    CALENDLY: 'calendly_config',
    CONVERSATION: 'conversation_config'
  }.freeze

  def initialize
    self.class.base_uri chatscommerce_api_url
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
    configuration_data = {
      configuration: {
        id: nil,
        key: config_key,
        data: config_data,
        store_id: store_id
      }
    }

    response = self.class.put(
      "#{chatscommerce_api_url}/api/configurations/",
      body: configuration_data.to_json,
      headers: self.class.headers
    )

    handle_response(response)

    response.parsed_response
  end

  private

  def handle_response(response)
    raise ConfigurationError, "Bad Request, url: #{response.request.last_uri}" if response.code == 404
    raise ConfigurationError, "Configurations cannot be created: #{response.code}" unless response.success?
  end

  def chatscommerce_api_url
    Rails.application.config.chatscommerce_api_url ||
      ENV['AI_BACKEND_API'] ||
      Rails.application.credentials.chatscommerce_api_url
  end
end