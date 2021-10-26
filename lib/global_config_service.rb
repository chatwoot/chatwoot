class GlobalConfigService
  def self.load(config_key, default_value)
    config = GlobalConfig.get(config_key)
    return config[config_key] if config[config_key].present?

    # To support migrating existing instance relying on env variables
    # TODO: deprecate this later down the line
    config_value = ENV[config_key] || default_value

    i = InstallationConfig.where(name: config_key).first_or_create(value: config_value)
    i.value
  end
end
