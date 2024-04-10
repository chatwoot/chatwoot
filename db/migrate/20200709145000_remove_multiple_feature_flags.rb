class RemoveMultipleFeatureFlags < ActiveRecord::Migration[6.0]
  def change
    current_config = InstallationConfig.where(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS').last
    InstallationConfig.where(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS').where.not(id: current_config.id).destroy_all
    ConfigLoader.new.process
    update_existing_accounts
  end

  def update_existing_accounts
    feature_config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    facebook_config = feature_config.value.find { |value| value['name'] == 'channel_facebook' }
    twitter_config = feature_config.value.find { |value| value['name'] == 'channel_twitter' }
    Account.find_in_batches do |account_batch|
      account_batch.each do |account|
        account.enable_features('channel_facebook') if facebook_config['enabled']
        account.enable_features('channel_twitter') if twitter_config['enabled']
        account.save!
      end
    end
  end
end
