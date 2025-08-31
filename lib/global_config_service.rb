class GlobalConfigService
  def self.load(config_key, default_value)
    config = GlobalConfig.get(config_key)[config_key]
    return config if config.present?

    # To support migrating existing instance relying on env variables
    # TODO: deprecate this later down the line
    config_value = ENV.fetch(config_key) { default_value }

    return if config_value.blank?

    i = InstallationConfig.where(name: config_key).first_or_initialize
    # Update the value if it's blank (nil or empty) and we have a valid config_value
    if i.value.blank? && config_value.present?
      i.value = config_value
      i.locked = false if i.new_record?
      i.save!
    elsif i.new_record?
      i.value = config_value
      i.locked = false
      i.save!
    end
    # To clear a nil value that might have been cached in the previous call
    GlobalConfig.clear_cache
    i.value
  end
end
