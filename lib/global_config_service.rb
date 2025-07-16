class GlobalConfigService
  def self.load(config_key, default_value)
    config = ENV.fetch(config_key) { GlobalConfig.get(config_key)[config_key] }
    return config if config.present?

    # To support migrating existing instance relying on env variables
    # TODO: deprecate this later down the line
    config_value = ENV.fetch(config_key) { default_value }

    return if config_value.blank?

    i = InstallationConfig.where(name: config_key).first_or_create(value: config_value, locked: false)
    # To clear a nil value that might have been cached in the previous call
    GlobalConfig.clear_cache
    i.value
  end
end
