class UpdateAccountDetails < ActiveRecord::Migration[7.1]
  def change
    InstallationConfig.where(name: 'INSTALLATION_PRICING_PLAN')
                      .update_all(serialized_value: { value: 'enterprise' }.with_indifferent_access)

    InstallationConfig.where(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
                      .update_all(serialized_value: { value: 10_000 }.with_indifferent_access)

    enterprise_features = %w[disable_branding audit_logs sla captain_integration custom_roles saml]
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    if config && config.value.present?
      features = config.value.map do |f|
        if enterprise_features.include?(f['name'])
          f.merge('enabled' => true)
        else
          f
        end
      end
      config.value = features
      config.save!
    end

    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each do |account|
        enterprise_features.each do |feature|
          account.enable_features!(feature)
        end
      end
    end
    GlobalConfig.clear_cache
  end
end
