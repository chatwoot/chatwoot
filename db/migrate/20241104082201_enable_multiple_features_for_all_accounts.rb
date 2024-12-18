class EnableMultipleFeaturesForAllAccounts < ActiveRecord::Migration[7.0]
  def change
    current_config = InstallationConfig.where(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS').last
    current_config.value.each do |v|
      if %w[ip_lookup email_continuity_on_api_channel custom_reply_email custom_reply_domain audit_logs sla help_center_embedding_search
            linear_integration].include?(v['name'])
        v['enabled'] = true
      end
    end
    current_config.save!

    ConfigLoader.new.process

    Account.find_in_batches do |account_batch|
      account_batch.each do |account|
        account.enable_features('ip_lookup')
        account.enable_features('email_continuity_on_api_channel')
        account.enable_features('custom_reply_email')
        account.enable_features('custom_reply_domain')
        account.enable_features('audit_logs')
        account.enable_features('sla')
        account.enable_features('help_center_embedding_search')
        account.enable_features('linear_integration')
        account.save!
      end
    end
  end
end
