class RepurposeMessageReplyToFlagForChannelAppStore < ActiveRecord::Migration[7.1]
  def up
    # The message_reply_to flag (deprecated) has been renamed to channel_app_store.
    # Disable it on any accounts that had message_reply_to enabled so the repurposed
    # flag starts in its intended default-off state.
    Account.feature_channel_app_store.find_each(batch_size: 100) do |account|
      account.disable_features(:channel_app_store)
      account.save!(validate: false)
    end
  end
end
