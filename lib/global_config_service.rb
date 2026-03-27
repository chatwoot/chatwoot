class GlobalConfigService
  def self.load(config_key, default_value)
    config = GlobalConfig.get(config_key)[config_key]
    return config if config.present?

    # To support migrating existing instance relying on env variables
    # TODO: deprecate this later down the line
    config_value = ENV.fetch(config_key) { default_value }

    return if config_value.blank?

    i = InstallationConfig.find_or_initialize_by(name: config_key)

    if i.value.blank?
      i.value = config_value
      i.locked = false if i.new_record?
      i.save if i.changed?
    end

    # To clear a nil value that might have been cached in the previous call
    GlobalConfig.clear_cache
    i.value
  end

  def self.account_signup_enabled?
    load('ENABLE_ACCOUNT_SIGNUP', 'false').to_s != 'false'
  end
end
