class AddNotificationDisplayDurationToNotificationSettings < ActiveRecord::Migration[7.1]
  def change
    add_column :notification_settings, :notification_display_duration, :integer, default: 6
  end
end
