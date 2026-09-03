class GlobalConfigService
  def self.load(config_key, default_value)
    config = GlobalConfig.get(config_key)[config_key]
    return config if configured_value?(config, config_key)

    installation_config = InstallationConfig.find_by(name: config_key)
    return installation_config.value if database_value_authoritative?(installation_config, config_key)

    # To support migrating existing instance relying on env variables
    # TODO: deprecate this later down the line
    config_value = ENV.fetch(config_key) { default_value }

    return if config_value.blank?

    installation_config ||= InstallationConfig.new(name: config_key)
    installation_config.value = config_value
    installation_config.locked = false if installation_config.new_record?
    installation_config.save!
    # To clear a nil value that might have been cached in the previous call
    GlobalConfig.clear_cache
    installation_config.value
  end

  def self.configured_value?(config, config_key)
    !ENV.key?(config_key) && !config.nil?
  end
  private_class_method :configured_value?

  def self.database_value_authoritative?(installation_config, config_key)
    installation_config.present? && !ENV.key?(config_key)
  end
  private_class_method :database_value_authoritative?

  def self.account_signup_enabled?
    load('ENABLE_ACCOUNT_SIGNUP', 'false').to_s != 'false'
  end
end
