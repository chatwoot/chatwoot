class RepurposeMessageReplyToFlagForChannelAppStore < ActiveRecord::Migration[7.1]
  def up
    # The message_reply_to flag (deprecated) has been renamed to channel_app_store.
    # Disable it on any accounts that had message_reply_to enabled so the repurposed
    # flag starts from plan/default configuration instead of inheriting stale state.
    Account.feature_channel_app_store.find_each(batch_size: 100) do |account|
      account.disable_features(:channel_app_store)
      account.save!(validate: false)
    end

    # Remove the stale message_reply_to entry from ACCOUNT_LEVEL_FEATURE_DEFAULTS.
    # ConfigLoader only adds new flags; it never removes renamed ones.
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    return if config&.value.blank?

    config.value = config.value.reject { |feature| feature['name'] == 'message_reply_to' }
    config.save!
    GlobalConfig.clear_cache
  end
end
