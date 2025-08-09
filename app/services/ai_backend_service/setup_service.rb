class AiBackendService::SetupService
  class SetupError < StandardError; end

  def self.setup_store(account, user_email)
    new.setup_store(account, user_email)
  end

  def self.save_configuration(store_id, config_key, config_data)
    new.save_configuration(store_id, config_key, config_data)
  end

  def setup_store(account, user_email)
    store_response = store_service.create_store(account, user_email)
    configuration_service.create_default_store_configs(store_response['store']['id'])
    store_response
  rescue AiBackendService::StoreService::StoreError,
         AiBackendService::ConfigurationService::ConfigurationError => e
    Rails.logger.error "AI Backend setup failed: #{e.message}"
    raise SetupError, "AI Backend setup failed: #{e.message}"
  end

  def save_configuration(store_id, config_key, config_data)
    configuration_service.save_configuration(store_id, config_key, config_data)
  rescue AiBackendService::ConfigurationService::ConfigurationError => e
    Rails.logger.error "Configuration creation failed: #{e.message}"
    raise SetupError, "Configuration creation failed: #{e.message}"
  end

  private

  def store_service
    @store_service ||= AiBackendService::StoreService.new
  end

  def configuration_service
    @configuration_service ||= AiBackendService::ConfigurationService.new
  end
end


