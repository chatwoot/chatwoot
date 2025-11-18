class EnableCaptainForAllAccounts < ActiveRecord::Migration[7.0]
  def up
    # Update the default feature flag config to enable captain_integration for new accounts
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    if config && config.value.present?
      features = config.value.map do |f|
        if f['name'] == 'captain_integration'
          f.merge('enabled' => true)
        else
          f
        end
      end
      config.value = features
      config.save!
    end

    # Enable captain_integration for all existing accounts in batches of 100
    # (if any accounts exist)
    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each { |account| account.enable_features!('captain_integration') }
    end

    GlobalConfig.clear_cache
  end

  def down
    # Disable captain_integration for all existing accounts (if any exist)
    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each { |account| account.disable_features!('captain_integration') }
    end

    # Revert the default feature flag config
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    if config && config.value.present?
      features = config.value.map do |f|
        if f['name'] == 'captain_integration'
          f.merge('enabled' => false)
        else
          f
        end
      end
      config.value = features
      config.save!
    end

    GlobalConfig.clear_cache
  end
end

