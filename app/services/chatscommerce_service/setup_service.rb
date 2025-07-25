class ChatscommerceService::SetupService
  class SetupError < StandardError; end

  def self.setup_store(account, user_email)
    new.setup_store(account, user_email)
  end

  def self.create_configuration(store_id, config_key, config_data)
    new.create_configuration(store_id, config_key, config_data)
  end

  def setup_store(account, user_email)
    # 1. Create store
    store_response = store_service.create_store(account, user_email)

    # 2. Create default configurations
    configuration_service.create_default_store_configs(store_response['store']['id'])

    store_response
  rescue ChatscommerceService::StoreService::StoreError,
         ChatscommerceService::ConfigurationService::ConfigurationError => e
    Rails.logger.error "Chatscommerce setup failed: #{e.message}"
    raise SetupError, "Chatscommerce setup failed: #{e.message}"
  end

  def create_configuration(store_id, config_key, config_data)
    configuration_service.create_configuration(store_id, config_key, config_data)
  rescue ChatscommerceService::ConfigurationService::ConfigurationError => e
    Rails.logger.error "Configuration creation failed: #{e.message}"
    raise SetupError, "Configuration creation failed: #{e.message}"
  end

  private

  def store_service
    @store_service ||= ChatscommerceService::StoreService.new
  end

  def configuration_service
    @configuration_service ||= ChatscommerceService::ConfigurationService.new
  end
end