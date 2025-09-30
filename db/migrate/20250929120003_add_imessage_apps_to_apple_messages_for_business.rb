class AddImessageAppsToAppleMessagesForBusiness < ActiveRecord::Migration[7.1]
  def change
    add_column :channel_apple_messages_for_business, :imessage_apps, :jsonb, default: []
  end
end