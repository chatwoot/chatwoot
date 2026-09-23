class EnableCompaniesForExistingAccounts < ActiveRecord::Migration[7.1]
  def up
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    if config
      features = config.value
      companies = features.find { |feature| feature['name'] == 'companies' }
      if companies
        companies['enabled'] = true
        companies.delete('premium')
        config.update!(value: features)
        GlobalConfig.clear_cache
      end
    end

    accounts = ChatwootApp.chatwoot_cloud? ? Account.where("custom_attributes->>'plan_name' = ?", 'Startups') : Account.all
    accounts.find_each do |account|
      next if account.feature_enabled?('companies')

      account.enable_features('companies')
      account.save!
    end
  end
end
