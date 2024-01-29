class Internal::ReconcilePlanConfigService
  def perform
    return if ChatwootHub.pricing_plan != 'community'

    reconcile_premium_config
    reconcile_premium_features
  end

  private

  def config_path
    @config_path ||= Rails.root.join('enterprise/config')
  end

  def premium_config
    @premium_config ||= YAML.safe_load(File.read("#{config_path}/premium_installation_config.yml")).freeze
  end

  def reconcile_premium_config
    premium_config.each do |config|
      new_config = config.with_indifferent_access
      existing_config = InstallationConfig.find_by(name: new_config[:name])
      next if existing_config&.value == new_config[:value]

      existing_config&.update!(value: new_config[:value])
    end
  end

  def premium_features
    @premium_features ||= YAML.safe_load(File.read("#{config_path}/premium_features.yml")).freeze
  end

  def reconcile_premium_features
    Account.find_in_batches do |accounts|
      accounts.each do |account|
        account.disable_features!(*premium_features)
      end
    end
  end
end
