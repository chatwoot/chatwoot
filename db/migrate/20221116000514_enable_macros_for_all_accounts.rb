class EnableMacrosForAllAccounts < ActiveRecord::Migration[6.1]
  def change
    current_config = InstallationConfig.where(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS').last
    current_config.value.each { |v| v['enabled'] = true if v['name'] == 'macros' }
    current_config.save!

    ConfigLoader.new.process

    Account.find_in_batches do |account_batch|
      account_batch.each do |account|
        account.enable_features('macros')
        account.enable_features('channel_email')
        account.save!
      end
    end
  end
end
