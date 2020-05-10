class ConfigLoader
  DEFAULT_OPTIONS = {
    config_path: nil,
    reconcile_only_new: true
  }.freeze

  def process(options = {})
    options = DEFAULT_OPTIONS.merge(options)
    # function of the "reconcile_only_new" flag
    # if true,
    #   it leaves the existing config and feature flags as it is and
    #   creates the missing configs and feature flags with their default values
    # if false,
    #   then it overwrites existing config and feature flags with default values
    #   also creates the missing configs and feature flags with their default values
    @reconcile_only_new = options[:reconcile_only_new]

    # setting the config path
    @config_path = options[:config_path].presence
    @config_path ||= Rails.root.join('config')

    # general installation configs
    reconcile_general_config

    # default account based feature configs
    reconcile_feature_config
  end

  private

  def general_configs
    @general_configs ||= YAML.safe_load(File.read("#{@config_path}/installation_config.yml")).freeze
  end

  def account_features
    @account_features ||= YAML.safe_load(File.read("#{@config_path}/features.yml")).freeze
  end

  def reconcile_general_config
    general_configs.each do |g_config|
      general_config = g_config.with_indifferent_access
      config = InstallationConfig.find_by(name: general_config[:name])

      if config
        # save config only if reconcile flag is false and existing configs value does not match default value
        save_as_new_config(general_config) if !@reconcile_only_new && config.value != general_config[:value]
      else
        save_as_new_config(general_config)
      end
    end
  end

  def save_as_new_config(general_config)
    general_config = general_config.with_indifferent_access
    config = InstallationConfig.new(name: general_config[:name])
    config.value = general_config[:value]
    config.save
  end

  def reconcile_feature_config
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')

    if config
      return false if config.value.to_s == account_features.to_s

      features = if @reconcile_only_new
                   (account_features + config.value).uniq { |h| h['name'] }
                 else
                   (config.value + account_features).uniq { |h| h['name'] }
                 end

      save_as_new_config({ name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS', value: features })
    else
      save_as_new_config({ name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS', value: account_features })
    end
  end
end
