class RepurposeChannelTwitterFlagForConversationUnreadCounts < ActiveRecord::Migration[7.1]
  def up
    # The channel_twitter flag (deprecated) has been renamed to conversation_unread_counts.
    # Disable it on any accounts that had channel_twitter enabled so the repurposed
    # flag starts in its intended default-off state.
    Account.feature_conversation_unread_counts.find_each(batch_size: 100) do |account|
      account.disable_features(:conversation_unread_counts)
      account.save!(validate: false)
    end

    # Remove the stale channel_twitter entry from ACCOUNT_LEVEL_FEATURE_DEFAULTS.
    # ConfigLoader only adds new flags; it never removes renamed ones.
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    return if config&.value.blank?

    config.value = config.value.reject { |feature| feature['name'] == 'channel_twitter' }
    config.save!
    GlobalConfig.clear_cache
  end
end
