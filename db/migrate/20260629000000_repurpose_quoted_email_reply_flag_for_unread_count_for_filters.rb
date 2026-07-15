class RepurposeQuotedEmailReplyFlagForUnreadCountForFilters < ActiveRecord::Migration[7.1]
  def up
    # The quoted_email_reply flag (deprecated) has been renamed to unread_count_for_filters.
    # Disable it on any accounts that had quoted_email_reply enabled so the repurposed
    # flag starts in its intended default-off state.
    Account.feature_unread_count_for_filters.find_each(batch_size: 100) do |account|
      account.disable_features(:unread_count_for_filters)
      account.save!(validate: false)
    end

    # Remove the stale quoted_email_reply entry from ACCOUNT_LEVEL_FEATURE_DEFAULTS.
    # ConfigLoader only adds new flags; it never removes renamed ones.
    # Leaving it would cause NoMethodError in enable_default_features when
    # creating new accounts (feature_quoted_email_reply= no longer exists).
    config = InstallationConfig.find_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    return if config&.value.blank?

    config.value = config.value.reject { |feature| feature['name'] == 'quoted_email_reply' }
    config.save!
    GlobalConfig.clear_cache
  end
end
