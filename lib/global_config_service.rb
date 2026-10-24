class GlobalConfigService
  def self.load(config_key, default_value)
    config = GlobalConfig.get(config_key)[config_key]
    return config if config.present? || config == false

    # To support migrating existing instance relying on env variables
    # TODO: deprecate this later down the line
    env_value = ENV.fetch(config_key, nil)
    config_value = ENV.fetch(config_key) { default_value }

    return if config_value.blank?

    i = InstallationConfig.find_or_initialize_by(name: config_key)
    persist_config(i, config_value, env_value)

    # Clear the cached blank even when another request created the configured value.
    GlobalConfig.clear_cache if i.value.present? || i.value == false
    i.value
  end

  def self.account_signup_enabled?
    load('ENABLE_ACCOUNT_SIGNUP', 'false').to_s != 'false'
  end

  # ConfigLoader seeds a row for every key in installation_config.yml, most of them blank.
  # A blank row must not shadow a value the operator set in the environment, otherwise the
  # env fallback above never applies on any instance that has run db:chatwoot_prepare.
  # A default value only fills a missing row; an existing row belongs to the super admin.
  def self.persist_config(config, config_value, env_value)
    if config.new_record?
      config.update!(value: config_value, locked: false)
    elsif blank_value?(config.value) && env_value.present?
      config.update!(value: env_value)
    end
  end

  def self.blank_value?(value)
    value.blank? && value != false
  end

  private_class_method :persist_config, :blank_value?
end
