class RemovePushNotificationSupport < ActiveRecord::Migration[7.2]
  def change
    drop_table :notification_subscriptions, if_exists: true

    remove_column :notification_settings, :push_flags, if_exists: true
  end
end